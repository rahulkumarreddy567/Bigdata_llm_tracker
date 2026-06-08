# Railway Docker Image Deployment

This project can be deployed to Railway from prebuilt Docker images instead of having Railway build from the repository.

## Why this mode

Use Docker images on Railway if you want:

- faster deploys
- repeatable image tags
- cleaner separation between image build and Railway runtime config

Railway supports deploying services directly from Docker images, including public images from GitHub Container Registry and Docker Hub. If a service source is a Docker image, Railway skips the build step. Railway also supports image auto-updates for images hosted on `ghcr.io` and Docker Hub.

## Images in this repo

This repo now includes a GitHub Actions workflow at:

- `.github/workflows/publish-railway-images.yml`

It publishes these images to GHCR:

- `ghcr.io/rahulkumarreddy567/bigdata-llm-tracker-airflow:latest`
- `ghcr.io/rahulkumarreddy567/bigdata-llm-tracker-elasticsearch:latest`
- `ghcr.io/rahulkumarreddy567/bigdata-llm-tracker-kibana:latest`

It also publishes SHA-tagged images for rollback-friendly deployments.

## Step 1: Publish the images

Push the repo to GitHub and run the `Publish Railway Images` workflow, or push to `main`.

After it finishes, confirm the packages exist in GHCR.

## Step 2: Create Railway services from images

Create these Railway services:

- `postgres`
- `elasticsearch`
- `kibana`
- `airflow-webserver`
- `airflow-scheduler`

Use these sources:

- `postgres`: Railway PostgreSQL template, or your own Postgres image
- `elasticsearch`: `ghcr.io/rahulkumarreddy567/bigdata-llm-tracker-elasticsearch:latest`
- `kibana`: `ghcr.io/rahulkumarreddy567/bigdata-llm-tracker-kibana:latest`
- `airflow-webserver`: `ghcr.io/rahulkumarreddy567/bigdata-llm-tracker-airflow:latest`
- `airflow-scheduler`: `ghcr.io/rahulkumarreddy567/bigdata-llm-tracker-airflow:latest`

For `airflow-scheduler`, override the start command to:

```bash
/bin/bash /opt/airflow/airflow-scheduler-start.sh
```

For `airflow-webserver`, use:

```bash
/bin/bash /opt/airflow/airflow-webserver-start.sh
```

For `kibana`, use:

```bash
/bin/bash /usr/local/bin/kibana-start.sh
```

## Step 3: Add volumes

Attach Railway volumes to:

- `elasticsearch` at `/usr/share/elasticsearch/data`
- `airflow-scheduler` at `/opt/airflow/data`

Optionally attach a volume to `airflow-webserver` at `/opt/airflow/data` too if you want the same persisted files available there.

Railway documents that stateful services persist data by attaching volumes to the relevant service.

## Step 4: Set variables

Set these variables on both Airflow services:

- `AIRFLOW__CORE__FERNET_KEY`
- `AIRFLOW_ADMIN_USERNAME`
- `AIRFLOW_ADMIN_PASSWORD`
- `AIRFLOW_ADMIN_EMAIL`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `KIBANA_URL`
- `ELASTICSEARCH_URL`

Recommended internal values:

- `KIBANA_URL=http://kibana.railway.internal:5601`
- `ELASTICSEARCH_URL=http://elasticsearch.railway.internal:9200`
- `POSTGRES_HOST=<your-postgres-service-host>`

Railway services can communicate over the project’s private network, and internal service addresses are the right fit for Elasticsearch/Kibana traffic.

## Step 5: Create the Kibana dashboard

Once `elasticsearch`, `kibana`, and `airflow-webserver` are healthy, open a shell in `airflow-webserver` and run:

```bash
/opt/airflow/create-kibana-dashboard.sh
```

## Private GHCR images

If your GHCR packages are private, Railway supports private registry credentials, including GHCR. Private registry pulls require a paid Railway plan.
