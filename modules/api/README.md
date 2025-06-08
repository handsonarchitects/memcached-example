# Cache API

## Running the Cache API (Docker)

```bash
docker compose up
```

## Verifying the Cache API

```bash
curl -X POST -H "Content-Type: application/json" -d '{"key": "my-key", "value": "my-value"}' localhost:8000/items/
curl localhost:8000/items/my-key
```