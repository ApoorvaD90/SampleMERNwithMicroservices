# Streaming App — MERN Microservices on AWS EKS

A containerized MERN stack application deployed on AWS EKS using Helm, with a Jenkins CI/CD pipeline, CloudWatch monitoring, and SNS/Slack notifications.

---

## Architecture

```
                         ┌─────────────────────────────────────────────────────┐
                         │                   Developer Machine                  │
                         │   git push ──► GitHub Repo ──► GitHub Webhook        │
                         └──────────────────────┬──────────────────────────────┘
                                                │
                                                ▼
                         ┌─────────────────────────────────────────────────────┐
                         │              Jenkins CI/CD Server                    │
                         │                                                      │
                         │  ┌──────────┐  ┌──────────┐  ┌───────────────────┐ │
                         │  │ Checkout │─►│  Build   │─►│   Push to ECR     │ │
                         │  │   SCM    │  │  Docker  │  │  (3 images)       │ │
                         │  └──────────┘  │  Images  │  └────────┬──────────┘ │
                         │                └──────────┘           │            │
                         │                                        ▼            │
                         │                            ┌───────────────────┐   │
                         │                            │  Deploy to EKS    │   │
                         │                            │  (helm upgrade)   │   │
                         │                            └────────┬──────────┘   │
                         │                                     │              │
                         │              post { success/failure }              │
                         │              ┌──────────┐  ┌────────┴──────────┐  │
                         │              │  Slack   │  │    AWS SNS        │  │
                         │              │ Webhook  │  │  Notification     │  │
                         │              └──────────┘  └───────────────────┘  │
                         └─────────────────────────────────────────────────────┘
                                                │
                         ┌──────────────────────▼──────────────────────────────┐
                         │                  AWS ECR                             │
                         │  streaming-app/helloservice                          │
                         │  streaming-app/profileservice                        │
                         │  streaming-app/frontend                              │
                         └──────────────────────┬──────────────────────────────┘
                                                │
                         ┌──────────────────────▼──────────────────────────────┐
                         │              AWS EKS Cluster (us-east-1)             │
                         │           streaming-app-cluster (t3.small)           │
                         │                                                      │
                         │  ┌───────────────────────────────────────────────┐  │
                         │  │          Namespace: ingress-nginx              │  │
                         │  │   nginx Ingress Controller (LoadBalancer)      │  │
                         │  │         AWS ELB ◄── Internet Traffic           │  │
                         │  └────────────────────┬──────────────────────────┘  │
                         │                       │                              │
                         │  ┌────────────────────▼──────────────────────────┐  │
                         │  │           Namespace: streaming-app             │  │
                         │  │                                                │  │
                         │  │  /              ┌─────────────────────────┐   │  │
                         │  │  ──────────────►│  Frontend (React/nginx) │   │  │
                         │  │                 │  2 replicas + HPA       │   │  │
                         │  │                 └─────────────────────────┘   │  │
                         │  │                                                │  │
                         │  │  /api/hello     ┌─────────────────────────┐   │  │
                         │  │  ──────────────►│  helloService (Node.js) │   │  │
                         │  │                 │  2 replicas + HPA       │   │  │
                         │  │                 └─────────────────────────┘   │  │
                         │  │                                                │  │
                         │  │  /api/profile   ┌─────────────────────────┐   │  │
                         │  │  ──────────────►│ profileService (Node.js)│   │  │
                         │  │                 │  2 replicas + HPA       │   │  │
                         │  │                 └──────────┬──────────────┘   │  │
                         │  │                            │                   │  │
                         │  │                 ┌──────────▼──────────────┐   │  │
                         │  │                 │  MongoDB (in-cluster)   │   │  │
                         │  │                 │  1 replica, emptyDir    │   │  │
                         │  │                 └─────────────────────────┘   │  │
                         │  └────────────────────────────────────────────────┘  │
                         │                                                      │
                         │  ┌───────────────────────────────────────────────┐  │
                         │  │       Namespace: amazon-cloudwatch             │  │
                         │  │  CloudWatch Agent DaemonSet + Fluent Bit       │  │
                         │  │  ──► CloudWatch Container Insights             │  │
                         │  │  ──► CloudWatch Log Groups                     │  │
                         │  └───────────────────────────────────────────────┘  │
                         └─────────────────────────────────────────────────────┘
```

---

## Project Description

This project demonstrates containerization and orchestration of a MERN stack application broken into microservices, deployed to AWS Elastic Kubernetes Service (EKS) via a fully automated Jenkins CI/CD pipeline.

The application consists of three independently deployable services:
- **helloService** — Express.js REST API returning a Hello World message (port 3001)
- **profileService** — Express.js + MongoDB REST API for user CRUD operations (port 3002)
- **Frontend** — React single-page app served via nginx, communicating with both backend services through the Ingress layer

Each service is independently containerized, stored in AWS ECR, and deployed via Helm. Horizontal Pod Autoscalers (HPA) are configured for all three services to scale based on CPU utilization.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, nginx |
| Backend | Node.js, Express.js |
| Database | MongoDB 6 |
| Containerization | Docker, multi-stage builds |
| Container Registry | AWS ECR |
| Orchestration | AWS EKS (Kubernetes) |
| Package Management | Helm 3 |
| Ingress | nginx Ingress Controller |
| Autoscaling | Kubernetes HPA |
| CI/CD | Jenkins (Pipeline from SCM) |
| Monitoring | AWS CloudWatch Container Insights, Fluent Bit |
| Notifications | AWS SNS (email), Slack Incoming Webhooks |
| IaC | Helm charts, Kubernetes manifests |

---

## Repository Structure

```
StreamingApp/
├── backend/
│   ├── helloService/          # Express API — GET / returns {"msg":"Hello World"}
│   │   ├── index.js
│   │   ├── Dockerfile
│   │   ├── .dockerignore
│   │   └── package.json
│   └── profileService/        # Express + MongoDB — user CRUD
│       ├── index.js
│       ├── Dockerfile
│       ├── .dockerignore
│       └── package.json
├── frontend/                  # React app
│   ├── src/
│   │   └── components/
│   │       └── Home.js        # Reads REACT_APP_HELLO_URL / REACT_APP_PROFILE_URL at build time
│   ├── nginx.conf
│   ├── Dockerfile             # Multi-stage: node build → nginx serve
│   └── package.json
├── helm/
│   └── streaming-app/
│       ├── Chart.yaml
│       ├── values.yaml        # Default values (no hardcoded env-specific values)
│       └── templates/
│           ├── _helpers.tpl
│           ├── helloservice-deployment.yaml
│           ├── helloservice-service.yaml
│           ├── profileservice-deployment.yaml
│           ├── profileservice-service.yaml
│           ├── frontend-deployment.yaml
│           ├── frontend-service.yaml
│           ├── mongodb-deployment.yaml
│           ├── mongodb-service.yaml
│           ├── mongodb-pvc.yaml
│           ├── ingress.yaml
│           └── hpa.yaml
├── docker-compose.yml         # Local development
├── Jenkinsfile                # CI/CD pipeline definition
├── .gitignore
└── README.md
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Docker Desktop | Latest | Local builds and compose |
| AWS CLI v2 | Latest | ECR auth, EKS config |
| kubectl | Latest | Kubernetes commands |
| Helm | 3.x | Chart deployment |
| eksctl | Latest | EKS cluster management |

---

## Local Development

### Run with Docker Compose

```bash
docker compose up --build
```

| URL | Expected response |
|-----|-------------------|
| http://localhost:3000 | React UI — shows "Hello World" |
| http://localhost:3001/health | `{"status":"OK"}` |
| http://localhost:3002/health | `{"status":"OK"}` |

```bash
docker compose down   # stop all containers
```

### Run services individually (without Docker)

**helloService:**
```bash
cd backend/helloService
echo "PORT=3001" > .env
npm install
node index.js
```

**profileService:**
```bash
cd backend/profileService
echo -e "PORT=3002\nMONGO_URL=mongodb://localhost:27017/streaming_app" > .env
npm install
node index.js
```

**Frontend:**
```bash
cd frontend
npm install
npm start     # development server at localhost:3000
```

---

## AWS Infrastructure Setup

### 1. IAM User

Create IAM user `streaming-app-user` with these policies:
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEC2FullAccess`
- `IAMFullAccess`
- `AmazonVPCFullAccess`
- `CloudWatchFullAccess`
- `AWSCloudFormationFullAccess`

### 2. ECR Repositories

Create three private repositories in AWS ECR:
- `streaming-app/helloservice`
- `streaming-app/profileservice`
- `streaming-app/frontend`

### 3. EKS Cluster

```bash
eksctl create cluster \
  --name streaming-app-cluster \
  --region us-east-1 \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed \
  --with-oidc \
  --asg-access
```

### 4. nginx Ingress Controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```

Get the public ELB hostname (your `INGRESS_HOST`):
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 5. Metrics Server (required for HPA)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## Jenkins CI/CD Pipeline

### Pipeline Stages

```
Checkout SCM
    │
    ▼
Build Docker Images (parallel)
    ├── helloService
    ├── profileService
    └── Frontend (with INGRESS_HOST build arg)
    │
    ▼
Push to ECR
    │
    ▼
Deploy to EKS (helm upgrade --install)
    │
    ▼
post {
    success → SNS email + Slack notification
    failure → SNS email + Slack notification
    always  → docker system prune
}
```

### Required Jenkins Credentials

| Credential ID | Kind | Value |
|--------------|------|-------|
| `aws-credentials-apoorva` | AWS Credentials | streaming-app-user Access Key + Secret |
| `INGRESS_HOST` | Secret text | ELB hostname from step 4 above |
| `ECR_REGISTRY` | Secret text | `<account-id>.dkr.ecr.us-east-1.amazonaws.com` |
| `EKS_CLUSTER_NAME` | Secret text | `streaming-app-cluster` |
| `SNS_TOPIC_ARN_APOORVA` | Secret text | `arn:aws:sns:us-east-1:<account-id>:streaming-app-deployments` |
| `SLACK_WEBHOOK_URL_APOORVA` | Secret text | Slack Incoming Webhook URL |

### GitHub Webhook

Add a webhook on your GitHub fork:
- **Payload URL:** `https://jenkinsacademics.herovired.com/github-webhook/`
- **Content type:** `application/json`
- **Events:** Just the push event

Every `git push` to `main` automatically triggers the pipeline.

---

## Helm Deployment

The Helm chart deploys all services into the `streaming-app` namespace. All environment-specific values are passed via `--set` at deploy time (no hardcoded values in the chart).

**Key Helm values:**

| Value | Default | Description |
|-------|---------|-------------|
| `global.imageRegistry` | `""` | ECR registry URL |
| `helloService.replicas` | `2` | Pod count |
| `helloService.hpa.enabled` | `true` | Enable autoscaling |
| `helloService.hpa.maxReplicas` | `10` | Max pods under load |
| `helloService.hpa.targetCPUUtilizationPercentage` | `70` | Scale trigger |
| `mongodb.persistence.enabled` | `true` | Use PVC for data (set to `false` if no EBS CSI driver) |
| `ingress.host` | `streaming-app.example.com` | ELB hostname |

**Manual deploy (local):**
```bash
helm upgrade --install streaming-app ./helm/streaming-app \
  --namespace streaming-app --create-namespace \
  --set global.imageRegistry=<ECR_REGISTRY> \
  --set helloService.image.tag=<TAG> \
  --set profileService.image.tag=<TAG> \
  --set frontend.image.tag=<TAG> \
  --set ingress.host=<INGRESS_HOST> \
  --set mongodb.persistence.enabled=false \
  --wait --timeout 5m
```

---

## Autoscaling

HPA is configured for all three services. To trigger a scale-up, run a load test:

```bash
kubectl run -i --tty load-generator --rm --image=busybox \
  --restart=Never -- /bin/sh -c \
  "while sleep 0.01; do wget -q -O- http://streaming-app-helloservice:3001/; done"
```

Watch HPAs react:
```bash
kubectl get hpa -n streaming-app --watch
```

| Service | Min | Max | CPU Target |
|---------|-----|-----|-----------|
| helloService | 2 | 10 | 70% |
| profileService | 2 | 10 | 70% |
| frontend | 2 | 10 | 70% |

---

## Monitoring

### CloudWatch Container Insights

Fluent Bit + CloudWatch Agent DaemonSet are deployed to the `amazon-cloudwatch` namespace to collect container metrics and logs.

**View metrics:**
AWS Console → CloudWatch → Container Insights → Performance monitoring → select `streaming-app-cluster`

**Log groups created:**
- `/aws/containerinsights/streaming-app-cluster/application`
- `/aws/containerinsights/streaming-app-cluster/performance`

### CloudWatch Alarm

A CPU alarm is configured on `pod_cpu_utilization` for the `streaming-app` namespace:
- **Threshold:** > 80%
- **Evaluation:** 3 consecutive 1-minute periods
- **Action:** SNS notification → email

---

## Notifications

### SNS (Email)
Build success/failure emails are sent via AWS SNS topic `streaming-app-deployments`. Subscribe your email to the topic and confirm the subscription.

### Slack
Build results are posted to a Slack channel via Incoming Webhook, directly from Jenkins post-build steps (curl to webhook URL stored as a Jenkins secret).

---

## Final Validation Checklist

```
[ ] docker compose up --build  →  localhost:3000 shows "Hello World"
[ ] ECR                        →  all 3 repositories have images
[ ] Jenkins pipeline           →  all stages green
[ ] kubectl get pods -n streaming-app  →  all pods Running
[ ] curl http://<INGRESS_HOST>/api/hello/    →  {"msg":"Hello World"}
[ ] curl http://<INGRESS_HOST>/api/profile/health  →  {"status":"OK"}
[ ] Browser at http://<INGRESS_HOST>         →  React UI loads
[ ] CloudWatch Container Insights            →  CPU/memory graphs visible
[ ] git push to main           →  Jenkins auto-triggers a new build
[ ] kubectl get hpa -n streaming-app         →  HPAs listed for all 3 services
```

---

## Known Limitations

- **MongoDB persistence:** EBS CSI driver is not installed by default on EKS. MongoDB uses `emptyDir` (in-memory storage) — data is lost on pod restart. Set `mongodb.persistence.enabled=true` only after installing the EBS CSI addon.
- **Frontend URLs are baked in at build time:** React environment variables (`REACT_APP_*`) are compiled into the static bundle. The frontend image must be rebuilt if the Ingress hostname changes.
- **Free-tier EKS:** Uses `t3.small` nodes to minimize cost. Not suitable for production workloads.

---

## Cost Note

The most expensive resources in this setup (delete when done):
1. **EKS Cluster** — `eksctl delete cluster --name streaming-app-cluster --region us-east-1`
2. **EC2 Nodes** — deleted automatically with the cluster
3. **ECR images** — delete repositories via AWS Console → ECR
4. **CloudWatch Log Groups** — delete via AWS Console → CloudWatch → Log groups
5. **ELB** — deleted automatically when nginx ingress namespace is removed
