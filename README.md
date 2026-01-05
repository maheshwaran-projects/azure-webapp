# Assessment 
create a public web application that connects to an Azure SQL database. The database should be seeded with a list of famous quotes, and when the site is accessed, it should query the database for a random quote and display it.

# Architecture
## System Overview

```mermaid
graph TB
    %% Styling
    classDef internet fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef agw fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef lb fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef k8s fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef sql fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef azure fill:#bbdefb,stroke:#0d47a1,stroke-width:2px
    
    %% Internet Layer
    INTERNET[External Users]:::internet
    
    %% Application Gateway Layer
    AGW[Application Gateway<br/>WAF_v2<br/>]:::agw
    
    %% Internal Load Balancer
    LB[Internal Load Balancer]:::lb
    
    %% Kubernetes Layer
    subgraph "Azure Kubernetes Service (AKS)"
        INGRESS[nginx-ingress Controller<br/>Health: /healthz]:::k8s
        
        subgraph "Flask Application"
            APP1[Flask App Pod 1<br/>Health: /health]:::k8s
            APP2[Flask App Pod 2<br/>Health: /health]:::k8s
            APP3[Flask App Pod 3<br/>Health: /health]:::k8s
        end
    end
    
    %% Azure SQL Layer
    SQL[Azure SQL Database<br/>Managed Identity Auth]:::sql
    
    %% Azure Services
    ACR[Azure Container Registry]:::azure
    
    %% Connections
    INTERNET -- "HTTPS<br/>https://quoteapp.centralindia.cloudapp.azure.com/quote" --> AGW
    AGW -- "Internal HTTP<br/>Port 80" --> LB
    
    %% Health Probe Flow (CORRECTED)
    AGW -. "Health Probe<br/>Port 80" .-> LB
    LB -- "Traffic" --> INGRESS
    INGRESS -- "Traffic Routing" --> APP1
    INGRESS -- "Traffic Routing" --> APP2
    INGRESS -- "Traffic Routing" --> APP3
    
    %% Internal Health Checks
    LB -. "Health Check<br/>/healthz" .-> INGRESS
    INGRESS -. "Readiness Probe<br/>/health" .-> APP1
    INGRESS -. "Readiness Probe<br/>/health" .-> APP2
    INGRESS -. "Readiness Probe<br/>/health" .-> APP3
    
    APP1 -- "Managed Identity<br/>Token-based Auth" --> SQL
    APP2 -- "Managed Identity<br/>Token-based Auth" --> SQL
    APP3 -- "Managed Identity<br/>Token-based Auth" --> SQL
    
    ACR -- "Container Images" --> INGRESS
```

## Architecture Explanation

### Flow Description:
1. **External Traffic**: Internet users access via HTTPS/HTTP
2. **Application Gateway**: Azure WAF_v2 provides security
3. **Internal Load Balancer**: Distributes traffic within VNET
4. **Kubernetes**: nginx-ingress routes to Flask pods
5. **Database**: Azure SQL with managed identity
6. **Registry**: ACR stores container images

### Key Features:
- ✅ WAF protection
- ✅ Private networking
- ✅ Managed identity authentication
- ✅ Health monitoring at every layer

### Application Url's
web application - https://quoteapp.centralindia.cloudapp.azure.com/quote
Adgocd - https://quoteapp.centralindia.cloudapp.azure.com/argocd

## Complete CI/CD Pipeline with Terraform & ArgoCD

### Architecture Diagram

```mermaid
graph TD
    %% Styling
    classDef dev fill:#e8f5e9,stroke:#2e7d32
    classDef git fill:#f3e5f5,stroke:#4a148c
    classDef terraform fill:#e1f5fe,stroke:#01579b
    classDef azure fill:#bbdefb,stroke:#0d47a1
    classDef helm fill:#fff3e0,stroke:#e65100
    classDef argocd fill:#f1f8e9,stroke:#33691e
    
    %% Developer Actions
    DEV[Developer]:::dev
    
    %% Repository Structure
    subgraph "Single Git Repository"
        INFRA_CODE[/terraform/<br/>main.tf, variables.tf/]:::terraform
        APP_CODE[/app/<br/>Flask Application/]:::dev
        HELM_CHART[/helm/<br/>templates/, values.yaml/]:::helm
    end
    
    %% Two Separate CI/CD Pipelines
    subgraph "Pipeline 1: Infrastructure CI/CD"
        PR_INFRA[Infra PR Created]:::terraform
        PLAN_ONLY[Terraform Plan<br/> Dry-run only]:::terraform
        APPROVE_INFRA[Approve & Merge]:::terraform
        TF_APPLY[Terraform Apply<br/> Updates Azure Cloud]:::terraform
    end
    
    subgraph "Pipeline 2: Application CI/CD"
        PR_APP[App PR Created]:::dev
        BUILD_TEST[Build & Test Image]:::dev
        APPROVE_APP[Approve & Merge]:::dev
        BUILD_PUSH[Build & Push to ACR]:::dev
        UPDATE_TAG[Update values.yaml<br/>image.tag: v1.2.0]:::helm
    end
    
    %% Azure Resources
    subgraph "Azure Cloud"
        AKS_RESOURCE[AKS Cluster]:::azure
        SQL_RESOURCE[SQL Database]:::azure
        VNET_RESOURCE[Virtual Network]:::azure
        ACR_RESOURCE[ACR Registry]:::azure
    end
    
    %% ArgoCD GitOps
    ARGOCD_WATCHER[ArgoCD<br/>Monitors code changes]:::argocd
    ARGOCD_SYNC[Auto-Sync to AKS]:::argocd
    
    %% Production
    PROD_APP[ Production App Running]:::azure
    
    %% Infrastructure Flow
    DEV -->|1. Modify terraform/| INFRA_CODE
    INFRA_CODE -->|2. Create PR| PR_INFRA
    PR_INFRA -->|3. Runs| PLAN_ONLY
    PLAN_ONLY -->|4. Review| APPROVE_INFRA
    APPROVE_INFRA -->|5. Merge triggers| TF_APPLY
    TF_APPLY -->|6. Deploys| AKS_RESOURCE
    TF_APPLY -->|7. Deploys| SQL_RESOURCE
    TF_APPLY -->|8. Deploys| VNET_RESOURCE
    
    %% Application Flow
    DEV -->|A. Modify app/| APP_CODE
    APP_CODE -->|B. Create PR| PR_APP
    PR_APP -->|C. Runs| BUILD_TEST
    BUILD_TEST -->|D. Review| APPROVE_APP
    APPROVE_APP -->|E. Merge triggers| BUILD_PUSH
    BUILD_PUSH -->|F. Stores image| ACR_RESOURCE
    BUILD_PUSH -->|G. Triggers| UPDATE_TAG
    UPDATE_TAG -->|H. Updates| HELM_CHART
    
    %% ArgoCD Flow
    HELM_CHART -->|I. Watched by Argocd https://quoteapp.centralindia.cloudapp.azure.com/argocd| ARGOCD_WATCHER
    ARGOCD_WATCHER -->|J. Auto-syncs| ARGOCD_SYNC
    ARGOCD_SYNC -->|K. Deploys| PROD_APP
```

**Two Separate CI/CD Pipelines:**

1. **Infrastructure Pipeline** (`/terraform/` folder):
   - PR → `terraform plan` (safety check only)
   - Merge → `terraform apply` (deploys to Azure)

2. **Application Pipeline** (`/app/` folder):
   - PR → Build & test Docker image
   - Merge → Push to ACR → Update Helm → ArgoCD auto-deploys

**One-Line Summary:** Code → PR → Review → Merge → Auto-deploy to production
-  High availability with multiple pods
```
