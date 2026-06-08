# Oracle Cloud Always Free Deployment

This project is prepared for deployment on an Oracle Cloud Always Free Ubuntu VM.

## Why Oracle Free Tier

Oracle Cloud Always Free is a better fit for this project than free PaaS platforms because this stack includes multiple stateful Docker services:

- Airflow
- PostgreSQL
- Elasticsearch
- Kibana

An Ubuntu VM lets you run the existing Docker-based stack directly.

## Files

- `llm_tracker/deploy/oracle-bootstrap.sh`
- `llm_tracker/deploy/deploy-vm.sh`
- `llm_tracker/deploy/docker-compose.cloud.yml`
- `llm_tracker/deploy/.env.cloud.example`

## Recommended Oracle setup

- Create an **Always Free** Ubuntu VM.
- Allow these ingress ports in the OCI network security list or NSG:
  - `22` for SSH
  - `8080` for Airflow
  - `5601` for Kibana
- Do not expose `9200` publicly.

## Deploy steps

1. SSH into the Ubuntu VM.
2. Run:

```bash
git clone https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git
cd Bigdata_llm_tracker/llm_tracker
chmod +x deploy/oracle-bootstrap.sh deploy/deploy-vm.sh
./deploy/oracle-bootstrap.sh
```

3. Edit:

```bash
deploy/.env.cloud
```

4. Replace the placeholder values:

- `POSTGRES_PASSWORD`
- `AIRFLOW_FERNET_KEY`
- `AIRFLOW_ADMIN_PASSWORD`
- `AIRFLOW_ADMIN_EMAIL`

5. Deploy:

```bash
./deploy/deploy-vm.sh
```

## Access

- Airflow: `http://<oracle-vm-public-ip>:8080`
- Kibana: `http://<oracle-vm-public-ip>:5601`

## Notes

- `oracle-bootstrap.sh` installs Docker Engine and the Docker Compose plugin on Ubuntu.
- `deploy-vm.sh` brings up the stack and creates the Kibana dashboard automatically.
- Elasticsearch is bound to localhost in the cloud compose file and should stay private.
