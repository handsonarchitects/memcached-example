# Contributing to Memcached Example

Thank you for your interest in contributing to this project! This guide will help you set up your development environment and understand our development workflow.

## Development Setup

### Prerequisites

- Python 3.11 or 3.12
- Docker
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured

### Install Development Dependencies

For each module, install both runtime and development dependencies:

```bash
# For cache-api module
cd modules/cache-api
pip install -r requirements.txt -r requirements-dev.txt

# For cache-generator module
cd modules/tools/cache-generator
pip install -r requirements.txt -r requirements-dev.txt
```

### Local Testing

Run the same checks locally before pushing:

```bash
# Code formatting
black --check .
black .  # to fix formatting

# Import sorting
isort --check-only .
isort .  # to fix imports

# Linting
flake8 .

# Type checking
mypy . --ignore-missing-imports

# Unit tests
pytest -v

# Security checks
# Note: safety check command is deprecated but safety scan requires authentication
safety check
bandit -r .
```

### Security Scanning Notes

**Safety Command**: The `safety check` command is deprecated but still functional. The new `safety scan` command requires authentication which isn't suitable for CI/CD environments. We continue using `safety check` until a better solution is available.

**Alternative**: Consider using `pip-audit` as a modern alternative:
```bash
pip install pip-audit
pip-audit
```

## Code Quality Standards

- **Line Length**: Maximum 120 characters
- **Import Sorting**: Using `isort` with Black profile
- **Type Hints**: Required for all functions (enforced by mypy)
- **Test Coverage**: Unit tests required for new functionality
- **Security**: No known vulnerabilities allowed in dependencies

## Configuration Files

This project uses a hybrid configuration approach for optimal tool support:

### **pyproject.toml** (Modern Tools)
Contains configuration for:
- **Black** (code formatter)
- **isort** (import sorter)
- **mypy** (type checker)
- **pytest** (test runner)

### **setup.cfg** (Traditional Tools)
Contains configuration for:
- **flake8** (linter)

**Why this hybrid approach?**
- `pyproject.toml` is the modern Python standard (PEP 518) for newer tools
- `setup.cfg` provides native flake8 support without requiring additional plugins
- This combination is reliable, widely used, and doesn't require flake8-pyproject dependencies
- Both files are automatically discovered by their respective tools

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration with the following workflows:

### 1. Python CI Workflow (`python-ci.yml`)

#### Pipeline Triggers
- **Push** to `main` branch
- **Pull requests** targeting `main` branch

#### Pipeline Jobs

##### Test Job
- **Matrix Strategy**: Tests against Python 3.11 and 3.12
- **Modules Tested**: `cache-api` and `tools/cache-generator`
- **Steps**:
  - Dependency caching for faster builds
  - Code linting with `flake8`
  - Code formatting validation with `black`
  - Import sorting validation with `isort`
  - Type checking with `mypy`
  - Unit testing with `pytest`

##### Docker Build Job
- Builds Docker images for both modules
- Validates that containers can be created successfully
- Runs only after tests pass

##### Security Scan Job
- Vulnerability scanning with `safety`
- Security linting with `bandit`
- Generates security reports

### 2. Kubernetes E2E Workflow (`k8s-e2e.yml`)

#### Pipeline Triggers
- **Push** to `main` branch
- **Pull requests** targeting `main` branch
- **Manual dispatch** for on-demand testing

#### Pipeline Steps
1. **Cluster Setup**: Creates a Kind Kubernetes cluster with 3 nodes
2. **Image Building**: Builds all Docker images (API, sidecar, cache-generator)
3. **Image Loading**: Loads images into Kind cluster
4. **Memcached Deployment**: Deploys high-availability Memcached cluster using Helm
5. **API Deployment**: Deploys cache API with sidecar proxy
6. **Health Verification**: Tests API health endpoints
7. **Load Generation**: Runs cache-generator job to simulate load
8. **Cache Verification**: Tests cache operations (set/get) through API
9. **Log Collection**: Gathers diagnostics for troubleshooting

## Development Workflow

1. **Fork** the repository
2. **Clone** your fork locally
3. **Create** a feature branch from `main`
4. **Make** your changes
5. **Run** local tests and quality checks
6. **Commit** your changes with clear commit messages
7. **Push** to your fork
8. **Create** a pull request to the main repository

## Testing

### Running Tests Locally

```bash
# Run all tests for cache-api
cd modules/cache-api
pytest -v

# Run all tests for cache-generator
cd modules/tools/cache-generator
pytest -v
```

### Integration Testing with Kubernetes

You can run the full integration test locally using the provided scripts:

#### Quick Start with Integration Script

```bash
# Run full integration test (setup + deploy + test + cleanup)
./scripts/integration-test.sh run

# Or use individual commands:
./scripts/integration-test.sh setup    # Setup cluster and deploy apps
./scripts/integration-test.sh test     # Run load generation and tests
./scripts/integration-test.sh logs     # Show diagnostics
./scripts/integration-test.sh cleanup  # Clean up resources
```

#### Prerequisites for Local K8s Testing
- **Docker** installed and running
- **kubectl** configured
- **Helm** installed
- **Kind** or **minikube** for local cluster

#### Manual Step-by-Step Process

```bash
# 1. Start your local Kubernetes cluster (Kind example)
kind create cluster --name memcached-test

# 2. Run the setup script to deploy applications
./scripts/setup.sh

# 3. Wait for deployments to be ready
kubectl rollout status deployment/memcached-api -w

# 4. Generate load using the cache-generator
./scripts/generate-load.sh

# 5. Monitor the job progress
kubectl get jobs -w
kubectl logs -f job/tools-cache-generator

# 6. Test the API manually
kubectl port-forward service/memcached-api 8080:8000 &
curl http://localhost:8080/health
curl -X POST -H "Content-Type: application/json" \
  -d '{"key": "test", "value": "hello"}' \
  http://localhost:8080/items/
curl http://localhost:8080/items/test

# 7. Cleanup
./scripts/destroy.sh
kind delete cluster --name memcached-test
```

#### GitHub Actions E2E Tests

The Kubernetes E2E workflow automatically:
- Creates a Kind cluster with multi-node setup
- Builds and loads all Docker images
- Deploys Memcached cluster using Helm
- Deploys the cache API with sidecar proxy
- Runs load generation jobs
- Verifies cache operations work end-to-end
- Collects logs for debugging

**Manual Trigger**: You can manually trigger the E2E workflow from the GitHub Actions tab in your repository.

### Writing Tests

- Use descriptive test function names that explain what is being tested
- Include comprehensive docstrings
- Mock external dependencies (like Memcached, HTTP requests)
- Test both success and failure scenarios

## Docker Development

### Building Images Locally

```bash
# Build cache-api image
cd modules/cache-api
docker build -t memcached-cache-api:dev .

# Build cache-generator image
cd modules/tools/cache-generator
docker build -t memcached-cache-generator:dev .
```

## Submitting Changes

### Pull Request Guidelines

- **Clear Description**: Explain what your PR does and why
- **Small Changes**: Keep PRs focused on a single feature or fix
- **Tests**: Include tests for new functionality
- **Documentation**: Update documentation if needed
- **Code Quality**: Ensure all CI checks pass

### Commit Message Format

Use clear, descriptive commit messages:

```
feat: add range calculator class for cache-generator
fix: handle missing environment variables gracefully
docs: update configuration documentation
test: add comprehensive payload validation tests
```

### Running GitHub Actions Locally

You can run GitHub Actions workflows locally for testing before pushing:

#### Using Act (Recommended)

```bash
# Install Act (macOS)
brew install act

# Install Act (Linux)
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run Python CI workflow
act push -W .github/workflows/python-ci.yml

# Run Kubernetes E2E workflow
act push -W .github/workflows/k8s-e2e.yml \
  --container-architecture linux/amd64 \
  -P ubuntu-latest=catthehacker/ubuntu:act-latest \
  --privileged
```

#### Act Compatibility

**Solution**: The K8s E2E workflow uses external configuration files to ensure compatibility:
- `k8s-e2e.yml` - Works with both GitHub Actions and Act
- `.github/kind-config.yaml` - Separate Kind cluster configuration file
- External tool installation steps compatible with Act runners

#### Prerequisites for Local Act Execution
- **Docker** with at least 4GB RAM and 2 CPU cores
- **Act** tool installed
- **Privileged mode** for Kind cluster creation

#### Common Act Issues and Solutions

1. **Docker resource constraints**
   ```bash
   # Increase Docker resources in Docker Desktop settings
   # Memory: 4GB+, CPUs: 2+
   ```

2. **Permission issues**
   ```bash
   # Run Act with privileged mode and Docker socket access
   act push --privileged -v /var/run/docker.sock:/var/run/docker.sock
   ```

#### Alternative Methods

1. **Local Integration Script**: Use `./scripts/integration-test.sh` for local testing
2. **Pre-commit Hooks**: Set up hooks to run quality checks before commits
3. **VS Code Extensions**: Use GitHub Actions extension for validation
4. **Draft PRs**: Push to draft PRs to run actions without affecting main branch

## Getting Help

If you have questions or need help:

1. Check existing [Issues](https://github.com/handsonarchitects/memcached-example/issues)
2. Review the [README.md](README.md) for basic usage
3. Open a new issue if you can't find what you're looking for

## Code of Conduct

Please be respectful and professional in all interactions. We're here to learn and build something great together!
