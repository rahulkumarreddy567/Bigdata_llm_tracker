#!/usr/bin/env bash
set -euxo pipefail

REPO_URL="${REPO_URL:-https://github.com/rahulkumarreddy567/Bigdata_llm_tracker.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"
APP_DIR="${APP_DIR:-/opt/Bigdata_llm_tracker}"

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git ufw
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER" || true

sudo rm -rf "$APP_DIR"
sudo git clone --branch "$REPO_BRANCH" "$REPO_URL" "$APP_DIR"
sudo chown -R "$USER:$USER" "$APP_DIR"

cd "$APP_DIR/llm_tracker"
if [[ ! -f deploy/.env.cloud && -f deploy/.env.cloud.example ]]; then
  cp deploy/.env.cloud.example deploy/.env.cloud
fi

sudo ufw allow 22/tcp || true
sudo ufw allow 8080/tcp || true
sudo ufw allow 5601/tcp || true
sudo ufw --force enable || true

echo
echo "Oracle VM bootstrap complete."
echo "Edit: $APP_DIR/llm_tracker/deploy/.env.cloud"
echo "Then run: cd $APP_DIR/llm_tracker && ./deploy/deploy-vm.sh"
