#!/usr/bin/env bash
set -euxo pipefail

REPO_URL="${REPO_URL:-https://github.com/your-org/llm_tracker_final.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
APP_DIR="${APP_DIR:-/opt/llm_tracker_final}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${VERSION_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker

if ! id -u ubuntu >/dev/null 2>&1; then
  useradd -m -s /bin/bash ubuntu
fi
usermod -aG docker ubuntu || true

rm -rf "$APP_DIR"
git clone --branch "$REPO_BRANCH" "$REPO_URL" "$APP_DIR"
cd "$APP_DIR/llm_tracker"

if [[ ! -f deploy/.env.cloud && -f deploy/.env.cloud.example ]]; then
  cp deploy/.env.cloud.example deploy/.env.cloud
fi

chown -R ubuntu:ubuntu "$APP_DIR"

cat >/etc/systemd/system/llm-tracker-deploy.service <<EOF
[Unit]
Description=LLM Tracker EC2 deployment
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
User=ubuntu
WorkingDirectory=$APP_DIR/llm_tracker
ExecStart=/bin/bash $APP_DIR/llm_tracker/deploy/deploy-vm.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable llm-tracker-deploy.service
systemctl start llm-tracker-deploy.service || true
