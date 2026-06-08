# AWS EC2 Deployment

This project is prepared for an Ubuntu-based EC2 instance.

## Recommended instance setup

- AMI: Ubuntu Server LTS
- Storage: at least 30 GB gp3
- Security group:
  - SSH `22` from your IP only
  - Airflow `8080` from your IP or admin network
  - Kibana `5601` from your IP or admin network
  - Do not expose Elasticsearch `9200` publicly

## Files for EC2

- `llm_tracker/deploy/ec2-user-data.sh`
- `llm_tracker/deploy/deploy-vm.sh`
- `llm_tracker/deploy/docker-compose.cloud.yml`
- `llm_tracker/deploy/.env.cloud.example`

## Before launch

1. Create an EC2 key pair or plan to use EC2 Instance Connect.
2. Create a security group with the ports above.
3. Edit `llm_tracker/deploy/.env.cloud.example` values locally and keep a real `.env.cloud` ready.
4. If using `ec2-user-data.sh`, replace the placeholder `REPO_URL`.

## Launch flow

1. Launch an Ubuntu EC2 instance.
2. Paste `llm_tracker/deploy/ec2-user-data.sh` into EC2 user data, or copy it onto the server after launch.
3. Connect to the instance.
4. Verify Docker:

```bash
docker --version
docker compose version
```

5. Move your real `.env.cloud` to:

```bash
/opt/llm_tracker_final/llm_tracker/deploy/.env.cloud
```

6. Run:

```bash
cd /opt/llm_tracker_final/llm_tracker
./deploy/deploy-vm.sh
```

## Access

- Airflow: `http://<ec2-public-ip>:8080`
- Kibana: `http://<ec2-public-ip>:5601`

## Useful checks

```bash
docker compose -f deploy/docker-compose.cloud.yml --env-file deploy/.env.cloud ps
docker compose -f deploy/docker-compose.cloud.yml --env-file deploy/.env.cloud logs kibana
docker compose -f deploy/docker-compose.cloud.yml --env-file deploy/.env.cloud logs airflow-webserver
```

## Hardening next

- Put Nginx or an AWS Application Load Balancer in front of Airflow and Kibana.
- Restrict security group ingress to trusted IP ranges.
- Store secrets outside the repo and copy them to `.env.cloud` during provisioning.
