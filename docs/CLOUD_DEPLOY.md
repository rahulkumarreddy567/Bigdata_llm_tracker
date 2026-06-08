# Cloud Deployment

This project now includes a cloud-ready deployment bundle under `llm_tracker/deploy/`.

## Recommended target

Use a single Ubuntu VM with Docker and the Docker Compose plugin installed. This project runs multiple stateful services together:

- Airflow webserver
- Airflow scheduler
- PostgreSQL
- Elasticsearch
- Kibana

## Files

- `llm_tracker/Dockerfile.cloud`
- `llm_tracker/deploy/docker-compose.cloud.yml`
- `llm_tracker/deploy/.env.cloud.example`
- `llm_tracker/deploy/deploy-vm.sh`

## Deploy steps on the VM

1. Clone the repository.
2. Copy `llm_tracker/deploy/.env.cloud.example` to `llm_tracker/deploy/.env.cloud`.
3. Set strong passwords and a real Fernet key.
4. Run:

```bash
cd llm_tracker
chmod +x deploy/deploy-vm.sh
./deploy/deploy-vm.sh
```

## Important notes

- Elasticsearch is bound to `127.0.0.1` by default in the cloud compose file so it is not publicly exposed.
- Airflow and Kibana are still exposed on their configured ports; protect them with cloud firewall rules or a reverse proxy.
- The deploy script creates the Kibana dashboard automatically after Kibana becomes healthy.
