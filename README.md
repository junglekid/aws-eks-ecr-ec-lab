# aws-eks-ecr-ec-lab

# Amazon S3 Security
![Aamzon S3 Security](./images/aws-s3-security.png)
## Use TerraForm to build the following:
* Amazon Elastic Kubernetes Service (EKS)
* Amazon Elastic Container Registry (ECR)
* Amazon ElastiCache
* AWS Key Management Service (KMS)
* Amazon Route 53
* AWS Certificate Manager (ACM)
* Amazon Virtual Private Cloud (Amazon VPC)
* IAM policies and roles
## Set variables in locals.tf
* aws region
* aws profile
* tags
* s3 bucket prefix name
## Update S3 Backend in provider.tf
* bucket
* key
* profile
* dynamodb_table
## Run Terraform
1. Run the following Terraform commands
    ```
    terraform init
    terraform validate
    terraform plan -out=plan.out
    terraform apply plan.out
    ```
2. Check Terraform apply results
    
    ![](./images/terraform-apply.png)

# Configure kubectl and EKS Cluster
EKS Cluster details can be extracted from terraform output or from AWS Console to get the name of cluster. This following command can be used to update the kubeconfig in your local machine where you run kubectl commands to interact with your EKS Cluster.
```
AWS_REGION=$(terraform output -raw aws_region)
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
```

Run update-kubeconfig command

~/.kube/config file gets updated with cluster details and certificate from the below command

# Create Docker Image and Upload to ECR
```
AWS_REGION=$(terraform output -raw aws_region)
ECR_REPO=$(terraform output -raw ecr_repo_url)
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
docker build --platform linux/amd64 --no-cache --pull -t ${ECR_REPO}:latest ./color
docker push ${ECR_REPO}:latest
```

# Install Metrics Server
```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system
```

# Install AWS Load Balancer Controller
```
AWS_REGION=$(terraform output -raw aws_region)
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
SA_ALB_NAME=$(terraform output -raw k8s_sa_alb_name)
helm repo add eks https://aws.github.io/eks-charts
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set region=$AWS_REGION \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=$SA_ALB_NAME
```

# Install External DNS 
```
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
DOMAIN_FILTER=$(terraform output -raw domain_filter)
SA_EXTERNAL_DNS_NAME=$(terraform output -raw k8s_sa_external_dns_name)
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns
helm upgrade --install external-dns external-dns/external-dns \
  --namespace kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=$SA_EXTERNAL_DNS_NAME \
  --set domainFilters={$DOMAIN_FILTER}
```

# Install Color App
```
ECR_REPO=$(terraform output -raw ecr_repo_url)
ELASTICACHE_HOST=$(terraform output -raw elasticache_host)
ELASTICACHE_PORT=$(terraform output -raw elasticache_port)
ELASTICACHE_USER=$(terraform output -raw elasticache_user)
ELASTICACHE_PASSWORD=$(terraform output -raw elasticache_password)
SESSION_EXPIRATION=$(terraform output -raw elasticache_expiration)
SECRET_KEY=$(terraform output -raw elasticache_secret_key)
ACM_CERTIFICATE_ARN=$(terraform output -raw acm_certificate_arn)
COLOR_DNS_NAME=$(terraform output -raw color_dns_name)
helm upgrade --install color ./charts/color \
  --namespace color \
  --create-namespace \
  --set color.container.image.repository=$ECR_REPO \
  --set configMap.elasticacheHost=$ELASTICACHE_HOST \
  --set configMap.elasticachePort=$ELASTICACHE_PORT \
  --set configMap.elasticacheUser=$ELASTICACHE_USER \
  --set configMap.sessionExpiration=$SESSION_EXPIRATION \
  --set secret.elasticachePassword=$ELASTICACHE_PASSWORD \
  --set secret.secretKey=$SECRET_KEY \
  --set ingress.certificateArn=$ACM_CERTIFICATE_ARN \
  --set ingress.dnsHostname=$COLOR_DNS_NAME
```

### Test Color App
```
COLOR_URL=$(terraform output -raw color_url)
echo "Color URL: $COLOR_URL"
curl $COLOR_URL
```

### Uninstall Color App
```
helm uninstall --namespace color color
```

### Verify Color App removed successfully
```
kubectl -n color get all
kubectl -n color get ingresses
```

### Uninstall External DNS
```
helm uninstall --namespace kube-system external-dns
```

### Verify External DNS removed successfully
```
kubectl -n kube-system get all -l app.kubernetes.io/name=external-dns
```

# Uninstall AWS Load Balancer Controller
```
helm uninstall --namespace aws-load-balancer-controller
```

### Verify AWS Load Balancer Controller removed successfully
```
kubectl -n kube-system get all -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get ingressclasses -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Clean up Terraform
```
terraform destroy
```
