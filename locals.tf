locals {
  # AWS Provider 
  aws_region  = "us-west-2"  # Update with aws region
  aws_profile = "bsisandbox" # Update with aws profile

  # Account ID
  account_id = data.aws_caller_identity.current.account_id

  # Tags
  owner       = "Dallin Rasmuson" # Update with owner name
  environment = "Sandbox"
  project     = "AWS ElastiCache EKS and ECR Lab"

  # VPC Configuration
  vpc_name = "ec-eks-ecr-lab-vpc"
  vpc_cidr = "10.220.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  # ElastiCache Configuration
  elasticache_cluster_id = "ec-eks-ecr-redis-cluster"
  elasticache_username   = "elasticache-svc"
  elasticache_expiration = "30" # In Seconds

  # ECR Configuration
  ecr_repo_name = "ec-eks-ecr-lab"

  # EKS Configuration
  eks_cluster_name                          = "ec-eks-ecr-lab"
  eks_cluster_version                       = "1.27"
  eks_iam_role_prefix                       = "ec-eks-ecr-lab"
  eks_alb_service_account_name              = "sa-aws-load-balancer-controller"
  eks_alb_external_dns_service_account_name = "sa-external-dns"

  # ACM and Route53 Configuration
  public_domain      = "bsisandbox.com"                # Update with your root domain
  custom_domain_name = "ec-eks-ecr-lab.bsisandbox.com" # Update with your custom domain name
  route53_zone_id    = data.aws_route53_zone.public_domain.zone_id
}
