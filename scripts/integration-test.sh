#!/bin/bash

set -e

CLUSTER_NAME="memcached-test"
API_PORT="8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓ $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        error "Helm is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v kind &> /dev/null; then
        error "Kind is not installed or not in PATH"
        error "Install with: brew install kind (macOS) or go install sigs.k8s.io/kind@latest"
        exit 1
    fi
    
    success "All prerequisites are available"
}

# Create Kind cluster
create_cluster() {
    log "Creating Kind cluster '$CLUSTER_NAME'..."
    
    if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
        warn "Cluster '$CLUSTER_NAME' already exists, deleting it first..."
        kind delete cluster --name "$CLUSTER_NAME"
    fi
    
    # Use the same config file as GitHub Actions for consistency
    if [ -f ".github/kind-config.yaml" ]; then
        kind create cluster --name "$CLUSTER_NAME" --config .github/kind-config.yaml
    else
        # Fallback inline config if file doesn't exist
        cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
    protocol: TCP
- role: worker
- role: worker
EOF
    fi
    
    success "Kind cluster created successfully"
}

# Build and load images
build_images() {
    log "Building Docker images..."
    
    log "Building cache-api image..."
    docker build -t handsonarchitects/memcached-api:latest -f ./modules/cache-api/Dockerfile ./modules/cache-api
    
    log "Building memcached-sidecar image..."
    docker build -t handsonarchitects/memcached-sidecar:latest -f ./modules/memcached-sidecar/Dockerfile ./modules/memcached-sidecar
    
    log "Building cache-generator image..."
    docker build -t handsonarchitects/tools-cache-generator:latest -f ./modules/tools/cache-generator/Dockerfile ./modules/tools/cache-generator
    
    log "Loading images to Kind cluster..."
    kind load docker-image handsonarchitects/memcached-api:latest --name "$CLUSTER_NAME"
    kind load docker-image handsonarchitects/memcached-sidecar:latest --name "$CLUSTER_NAME"
    kind load docker-image handsonarchitects/tools-cache-generator:latest --name "$CLUSTER_NAME"
    
    success "Docker images built and loaded"
}

# Deploy applications
deploy_apps() {
    log "Deploying applications to Kubernetes..."
    
    # Add Helm repo and install Memcached
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    
    log "Installing Memcached cluster..."
    helm install memcached-cluster \
        --set architecture="high-availability" \
        --set replicaCount=2 \
        --wait --timeout=300s \
        bitnami/memcached
    
    log "Deploying cache API..."
    kubectl apply -f k8s/memcached-api-deployment.yaml
    kubectl apply -f k8s/memcached-api-service.yaml
    
    log "Waiting for deployments to be ready..."
    kubectl rollout status deployment/memcached-api --timeout=300s
    
    sleep 5  # Give some time for services to stabilize

    success "Applications deployed successfully"
}

# Generate load
generate_load() {
    log "Generating cache load..."
    
    kubectl apply -f k8s/tools-cache-generator-job.yaml
    
    log "Waiting for cache generator job to complete..."
    timeout=600  # 10 minutes
    elapsed=0
    interval=10
    
    while [ $elapsed -lt $timeout ]; do
        job_status=$(kubectl get job tools-cache-generator -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null || echo "")
        job_failed=$(kubectl get job tools-cache-generator -o jsonpath='{.status.conditions[?(@.type=="Failed")].status}' 2>/dev/null || echo "")
        
        if [ "$job_status" = "True" ]; then
            success "Cache generator job completed successfully!"
            break
        elif [ "$job_failed" = "True" ]; then
            error "Cache generator job failed!"
            kubectl describe job tools-cache-generator
            kubectl logs -l job-name=tools-cache-generator --tail=50
            return 1
        else
            log "Job still running... (elapsed: ${elapsed}s)"
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    if [ $elapsed -ge $timeout ]; then
        error "Job timed out after ${timeout} seconds"
        return 1
    fi
}

# Test API
test_api() {
    log "Testing API functionality..."
    
    # Start port-forward in background
    kubectl port-forward service/memcached-api "$API_PORT:8000" &
    PF_PID=$!
    
    # Wait for port-forward to be ready
    sleep 5
    
    # Test health endpoint
    log "Testing health endpoint..."
    if curl -s -f "http://localhost:$API_PORT/health" > /dev/null; then
        success "Health endpoint is working"
    else
        error "Health endpoint failed"
        kill $PF_PID 2>/dev/null || true
        return 1
    fi
    
    # Test cache operations
    log "Testing cache set operation..."
    if curl -s -X POST -H "Content-Type: application/json" \
        -d '{"key": "test-key", "value": "test-value"}' \
        "http://localhost:$API_PORT/items/" > /dev/null; then
        success "Cache set operation successful"
    else
        error "Cache set operation failed"
        kill $PF_PID 2>/dev/null || true
        return 1
    fi
    
    log "Testing cache get operation..."
    response=$(curl -s "http://localhost:$API_PORT/items/test-key" || echo "")
    if echo "$response" | grep -q "test-value"; then
        success "Cache get operation successful"
    else
        error "Cache get operation failed: $response"
        kill $PF_PID 2>/dev/null || true
        return 1
    fi
    
    # Cleanup port-forward
    kill $PF_PID 2>/dev/null || true
    success "API tests completed successfully"
}

# Show logs
show_logs() {
    log "Collecting logs and diagnostics..."
    
    echo "=== Cluster Info ==="
    kubectl cluster-info
    
    echo -e "\n=== Node Status ==="
    kubectl get nodes -o wide
    
    echo -e "\n=== All Pods ==="
    kubectl get pods --all-namespaces
    
    echo -e "\n=== Services ==="
    kubectl get svc
    
    echo -e "\n=== Recent Events ==="
    kubectl get events --sort-by=.metadata.creationTimestamp | tail -10
}

# Cleanup
cleanup() {
    log "Cleaning up resources..."
    kubectl delete job tools-cache-generator --ignore-not-found=true
    kubectl delete -f k8s/ --ignore-not-found=true
    helm uninstall memcached-cluster --ignore-not-found || true
    kind delete cluster --name "$CLUSTER_NAME" || true
    success "Cleanup completed"
}

# Main execution
main() {
    case "${1:-run}" in
        "run")
            log "Starting full integration test..."
            check_prerequisites
            create_cluster
            build_images
            deploy_apps
            generate_load
            test_api
            show_logs
            success "Integration test completed successfully!"
            ;;
        "setup")
            log "Setting up environment only..."
            check_prerequisites
            create_cluster
            build_images
            deploy_apps
            success "Environment setup completed!"
            ;;
        "test")
            log "Running tests only..."
            generate_load
            test_api
            success "Tests completed!"
            ;;
        "cleanup")
            cleanup
            ;;
        "logs")
            show_logs
            ;;
        *)
            echo "Usage: $0 [run|setup|test|cleanup|logs]"
            echo ""
            echo "Commands:"
            echo "  run     - Full integration test (default)"
            echo "  setup   - Setup cluster and deploy apps only"
            echo "  test    - Run load generation and API tests only"
            echo "  cleanup - Clean up all resources"
            echo "  logs    - Show logs and diagnostics"
            exit 1
            ;;
    esac
}

# Trap cleanup on exit
trap cleanup EXIT

main "$@"
