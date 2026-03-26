# DevOps Project 2 — Amazon Prime Clone (Fully Automated)

A fully automated CI/CD pipeline that builds, scans, and deploys an Amazon Prime Video clone application to AWS EKS using Jenkins, Docker, SonarQube, Trivy, ArgoCD, Helm, and Terraform — with Grafana + Prometheus monitoring.

---

## Architecture Overview

```
GitHub → Jenkins → SonarQube → npm Build → Trivy Scan
                                                 ↓
                                          Docker Image Build
                                                 ↓
                                            AWS ECR
                                                 ↓
                                    ArgoCD (GitOps Deployment)
                                                 ↓
                                    AWS EKS (Kubernetes Cluster)
                                                 ↓
                                  Grafana + Prometheus Monitoring
```

---

## Tech Stack

| Category | Tool |
|---|---|
| Source Control | GitHub |
| CI Orchestration | Jenkins |
| Code Quality | SonarQube |
| Build Tool | npm |
| Security Scan | Trivy (Aqua Security) |
| Containerization | Docker |
| Container Registry | AWS ECR |
| Infrastructure | Terraform |
| K8s Package Manager | Helm |
| GitOps Deployment | ArgoCD |
| Kubernetes | AWS EKS |
| Monitoring | Grafana + Prometheus |
| Notifications | Panda Cloud |

---

## Prerequisites

- AWS Account with IAM credentials
- Terraform >= 1.0
- AWS CLI configured
- kubectl installed
- Helm installed
- Git

---

## Project Structure

```
├── tf/
│   └── ec2_server/
│       ├── main.tf           # EC2 instance with user_data
│       ├── provider.tf       # AWS provider config
│       ├── variables.tf      # Variable declarations
│       ├── terraform.tfvars  # Variable values
│       ├── sg.tf             # Security group rules
│       ├── output.tf         # Output values
│       ├── install.sh        # Bootstrap script (Jenkins, Docker, SonarQube, Trivy)
│       └── key / key.pub     # SSH key pair
├── k8s/
│   ├── deployment.yaml       # Kubernetes deployment manifest
│   └── service.yaml          # Kubernetes service manifest
├── helm/
│   └── charts/               # Helm chart for the application
├── Jenkinsfile               # CI/CD pipeline definition
└── Dockerfile                # Docker image build instructions
```

---

## Infrastructure Setup (Terraform)

### Step 1 — Generate SSH Key Pair

```bash
cd tf/ec2_server
ssh-keygen -t rsa -b 4096 -f ./key -N ""
```

### Step 2 — Configure Variables

Edit `terraform.tfvars`:

```hcl
instance_type = "t2.medium"
ami           = "ami-0e86e20dae9224db8"
key_name      = "key"
volume_size   = 30
region_name   = "us-east-1"
server_name   = "JENKINS-SERVER"
```

### Step 3 — Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

---

## Jenkins Server — Installed via User Data

The `install.sh` script automatically installs:

- AWS CLI
- Docker + SonarQube (as Docker container on port 9000)
- Trivy (vulnerability scanner)
- Java 17 (OpenJDK)
- Jenkins (on port 8080)

Access after deployment:

```
Jenkins   → http://<EC2-PUBLIC-IP>:8080
SonarQube → http://<EC2-PUBLIC-IP>:9000  (admin/admin)
```

---

## Jenkins Pipeline Stages

| Stage | Description |
|---|---|
| 1. Git Checkout | Clone source code from GitHub |
| 2. SonarQube Analysis | Static code analysis |
| 3. Quality Gate | Fail pipeline if quality threshold not met |
| 4. npm Install | Install Node.js dependencies |
| 5. Trivy Scan | Scan filesystem for vulnerabilities |
| 6. Docker Build | Build Docker image |
| 7. Create ECR Repo | Create AWS ECR repository if not exists |
| 8. ECR Login & Tag | Authenticate and tag image |
| 9. Push to ECR | Push image to AWS ECR |
| 10. Cleanup | Remove local Docker images |

---

## Jenkins Configuration

### Required Plugins

- SonarQube Scanner
- NodeJS
- Docker Pipeline
- AWS Credentials
- Kubernetes CLI

### Credentials to Add

```
Manage Jenkins → Credentials → Add:

1. access-key   → AWS Access Key ID     (Secret text)
2. secret-key   → AWS Secret Access Key (Secret text)
3. sonar-token  → SonarQube Token       (Secret text)
```

### Tools to Configure

```
Manage Jenkins → Tools:

1. JDK     → Name: JDK,     Version: Java 21
2. NodeJS  → Name: NodeJS,  Version: 18.x
3. SonarQube Scanner → Name: SonarQube Scanner
```

---

## Security Group Ports

| Port | Service |
|---|---|
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |
| 8080 | Jenkins |
| 9000 | SonarQube |
| 9090 | Prometheus |
| 9100 | Node Exporter |
| 3000 | Grafana |
| 6443 | Kube API Server |
| 2379-2380 | etcd cluster |
| 10250-10260 | Kubernetes |
| 30000-32767 | NodePort services |

---

## Monitoring Setup

### Prometheus + Grafana via Helm

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring --create-namespace

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring
```

### Import Grafana Dashboard

- Dashboard ID: `1860` (Node Exporter Full)
- Datasource: Prometheus

---

## Cleanup Pipeline

To destroy all AWS resources and avoid charges:

```groovy
pipeline {
  agent any
  stages {
    stage('Cleanup ECR Images') {
      steps {
        withCredentials([
          string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY'),
          string(credentialsId: 'secret-key', variable: 'AWS_SECRET_KEY')
        ]) {
          sh """
            aws configure set aws_access_key_id $AWS_ACCESS_KEY
            aws configure set aws_secret_access_key $AWS_SECRET_KEY
            aws ecr delete-repository --repository-name amazon-prime \
              --region us-east-1 --force
          """
        }
      }
    }
    stage('Destroy EKS Cluster') {
      steps {
        sh 'terraform destroy -auto-approve'
      }
    }
    stage('Destroy EC2 / Jenkins Server') {
      steps {
        dir('tf/ec2_server') {
          sh 'terraform destroy -auto-approve'
        }
      }
    }
  }
}
```

Or run manually:

```bash
# Destroy EKS
cd tf/eks
terraform destroy -auto-approve

# Destroy EC2
cd tf/ec2_server
terraform destroy -auto-approve
```

---

## Common Errors & Fixes

| Error | Fix |
|---|---|
| `agents any` syntax error | Change to `agent any` |
| Jenkins GPG key not found | Use `gpg --dearmor` instead of `wget -O` |
| SSH connection timeout | Use `user_data` instead of `remote-exec` provisioner |
| `Bad substitution` in shell | Use double quotes for `${params.X}` |
| `$SCANNER_HOME` not found | Use single quotes `sh '''...'''` for shell vars |
| HTTP 403 CSRF error | Enable proxy compatibility in Jenkins security settings |

---

## Outputs



