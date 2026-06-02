#!/bin/bash
# EC2 user-data: install and run ShopEasy from GitHub on Ubuntu.
set -eux
exec > /var/log/userdata-ecommerce.log 2>&1

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3 python3-pip python3-venv git

APP_DIR=/opt/ecommerce
REPO_URL="https://github.com/srikanth454/E-COMMERCE.git"

rm -rf "$APP_DIR"
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn

cat > /etc/systemd/system/ecommerce.service << 'EOF'
[Unit]
Description=ShopEasy E-Commerce Flask App
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ecommerce
Environment=PATH=/opt/ecommerce/venv/bin
ExecStart=/opt/ecommerce/venv/bin/gunicorn -w 2 -b 0.0.0.0:5000 --timeout 120 app:app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ecommerce
systemctl start ecommerce

echo "ShopEasy deployment finished at $(date -Is)"
