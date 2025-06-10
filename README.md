## Running the Example

1. **Clone the repository**:

```bash
git clone https://github.com/handsonarchitects/memcached-example.git
cd memcached-example
```

2. Build Docker images, deploy the Memcached cluster & Cache API:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
./scripts/setup.sh
```

4. Verify the deployment:

```bash
kubectl run verify-api-health --image nginx:alpine --restart Never --rm -it --command -- curl memcached-api:8000/health

kubectl run run-cache-update --image nginx:alpine --restart Never --rm -it --command -- curl -X POST -H "Content-Type: application/json" -d '{"key": "my-key", "value": "my-value"}' memcached-api:8000/items/

kubectl run run-cache-get --image nginx:alpine --restart Never --rm -it --command -- curl memcached-api:8000/items/my-key
```

5. Generate load on the Memcached cluster:

```bash
./scripts/generate-load.sh
kubectl wait --for=condition=complete job/tools-cache-generator
```

6. Get stats from the Memcached cluster:

```bash
kubectl run get-memcached-stats --image nginx:alpine --restart Never --rm -it --command -- curl telnet://memcached-cluster-0.memcached-cluster:11211
```
and then type `stats` in the terminal to see the stats (`total_items`), then quit with `quit`.

```bash
kubectl run get-memcached-stats --image nginx:alpine --restart Never --rm -it --command -- curl telnet://memcached-cluster-1.memcached-cluster:11211
```
and then type `stats` in the terminal to see the stats (`total_items`), then quit with `quit`.

7. Destroy all resources:

```bash
./scripts/destroy.sh
```

