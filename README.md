flowchart TD
    DEV["💻 Developer Workstation"]
    GH["🐙 GitHub Repository\nyour-username/StreamingApp"]
    JK["🔧 Jenkins CI/CD\njenkinsacademics.herovired.com"]
    ECR["📦 AWS ECR\nhelloservice · profileservice · frontend"]
    CW["📊 AWS CloudWatch"]
    SNS["🔔 AWS SNS Topic"]
    EMAIL["📧 Email Notifications"]

    DEV -->|"git push"| GH
    GH -->|"webhook on push"| JK
    JK -->|"docker push :BUILD_NUM"| ECR
    JK -->|"helm upgrade --install"| NGC

    subgraph EKS["☁️ AWS EKS Cluster · streaming-app-cluster · us-east-1"]

        subgraph ING["Namespace: ingress-nginx"]
            ELB[/"🌐 AWS Elastic Load Balancer — INGRESS_HOST"/]
            NGC["nginx Ingress Controller"]
            ELB --> NGC
        end

        subgraph APP["Namespace: streaming-app"]
            HELLO["helloService\nDeployment · port 3001\nreplicas: 2 · HPA max: 10"]
            PROFILE["profileService\nDeployment · port 3002\nreplicas: 2 · HPA max: 10"]
            FRONT["Frontend — React + nginx\nDeployment · port 80\nreplicas: 2 · HPA max: 10"]
            MONGO[("MongoDB\nport 27017\n1Gi EBS PVC")]

            NGC -->|"/api/hello"| HELLO
            NGC -->|"/api/profile"| PROFILE
            NGC -->|"/"| FRONT
            PROFILE -->|"MONGO_URL"| MONGO
        end

        subgraph MON["Namespace: amazon-cloudwatch"]
            CWA["CloudWatch Agent — DaemonSet\nship metrics"]
            FB["Fluent Bit — DaemonSet\nship logs"]
        end

    end

    ECR -->|"imagePull"| HELLO
    ECR -->|"imagePull"| PROFILE
    ECR -->|"imagePull"| FRONT
    CWA -->|"pod metrics"| CW
    FB -->|"container logs"| CW
    CW -->|"CPU > 80% alarm"| SNS
    SNS -->|"email subscription"| EMAIL
