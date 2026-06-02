# E-COMMERCE

A simple Python e-commerce web application built with Flask.

## Features

- Product catalog with 6 items
- Place orders with quantity selection
- **Orders** page with order history, total order count, and revenue
- Order counter badge in the navigation bar

## Setup

```bash
pip install -r requirements.txt
python app.py
```

Open **http://127.0.0.1:5000** in your browser.

## Routes

| Route | Description |
|-------|-------------|
| `/` | Shop — browse and order products |
| `/orders` | View all orders and order statistics |

## Deploy on AWS EC2 (Ubuntu)

Scripts in `deploy/` provision an Ubuntu instance, open ports **22** (SSH) and **5000** (app), and install the app via **user-data**.

```bash
# From project root (requires AWS CLI configured)
bash deploy/launch-ec2.sh
```

- `deploy/userdata.sh` — clones this repo, installs dependencies, runs **gunicorn** on port 5000
- `deploy/launch-ec2.sh` — creates security group and launches the EC2 instance

After launch, open `http://<PUBLIC_IP>:5000` (allow 2–3 minutes for user-data to finish).

Environment variables for launch (optional):

| Variable | Default |
|----------|---------|
| `AWS_REGION` | `us-east-1` |
| `INSTANCE_TYPE` | `t2.micro` |
| `KEY_NAME` | `ec2-keys` |

## Local Kubernetes (KIND)

Single-node cluster on your machine (requires [Docker](https://www.docker.com/) and [kind](https://kind.sigs.k8s.io/)):

```bash
bash k8s/create-kind-cluster.sh
# or
kind create cluster --config k8s/kind-config.yaml --wait 10m
```

| Command | Description |
|---------|-------------|
| `kubectl get nodes` | Should show 1 node `Ready` |
| `kind delete cluster --name ecommerce` | Remove the cluster |

Context: `kind-ecommerce`

### Deploy app on Kubernetes (2 replicas)

```bash
bash k8s/deploy-k8s.sh
```

| Resource | Name |
|----------|------|
| Deployment | `ecommerce-app` (2 replicas) |
| Service | `ecommerce-service` (ClusterIP) |
| Ingress | `http://localhost/` |

Requires port **80** mapped on the KIND node (see `k8s/kind-config.yaml`). If Ingress is unreachable, recreate the cluster with that config.

## Tech Stack

- Python 3
- Flask 3
- Gunicorn (production on EC2)
- In-memory order storage (resets when the server restarts)
