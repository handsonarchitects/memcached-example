## Running the Example

1. **Clone the repository**:

```bash
git clone https://github.com/handsonarchitects/memcached-example.git
cd memcached-example
```

2. Build Docker images:

```bash
./scripts/build.sh
```

3. Deploy the Memcached cluster using Helm and Cache API:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
./scripts/start.sh
```

4. Verify the deployment:

```bash
kubectl run verify-api-health --image nginx:alpine --restart Never --rm -it --command -- curl memcached-api:8000/health

kubectl run run-cache-update --image nginx:alpine --restart Never --rm -it --command -- curl -X POST -H "Content-Type: application/json" -d '{"key": "my-key", "value": "my-value"}' memcached-api:8000/items/

kubectl run run-cache-get --image nginx:alpine --restart Never --rm -it --command -- curl memcached-api:8000/items/my-key
```

4. Destroy all resources:

```bash
./scripts/stop.sh
```

