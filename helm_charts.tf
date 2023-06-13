# Install Kubernetes Metric Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"

  depends_on = [
    module.eks,
    aws_eks_node_group.eks,
  ]
}

# Create ISRA Role for External DNS
module "external_dns_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                  = "${local.eks_iam_role_prefix}-external-dns"
  attach_external_dns_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

# Create K8S Service Account for External DNS 
resource "kubernetes_service_account" "external_dns_service_account" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "external-dns"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_dns_irsa_role.iam_role_arn
    }
  }

  depends_on = [
    module.eks,
    aws_eks_node_group.eks,
  ]
}

# Install External DNS Helm Chart
resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_dns_service_account.metadata[0].name
  }

  set_list {
    name  = "domainFilters"
    value = [local.public_domain]
  }

  depends_on = [
    module.eks,
    aws_eks_node_group.eks,
  ]
}

# Create Color K8S Namespace
resource "kubernetes_namespace" "color" {
  metadata {
    annotations = {
      name = "color"
    }

    labels = {
      "kubernetes.io/metadata.name" = "color"
    }

    name = "color"
  }

  depends_on = [
    module.eks,
    aws_eks_node_group.eks,
  ]
}

# Install Color Helm Chart
resource "helm_release" "color" {
  name      = "color"
  chart     = "./charts/color"
  namespace = kubernetes_namespace.color.metadata[0].name

  set {
    name  = "color.container.image.repository"
    value = module.ecr.repository_url
  }

  set {
    name  = "configMap.elasticacheHost"
    value = aws_elasticache_replication_group.elasticache.configuration_endpoint_address
  }

  set {
    name  = "configMap.elasticachePort"
    value = aws_elasticache_replication_group.elasticache.port
  }

  set {
    name  = "configMap.elasticacheUser"
    value = aws_elasticache_user.elasticache.user_name
  }

  set {
    name  = "configMap.sessionExpiration"
    value = local.elasticache_expiration
  }

  set {
    name  = "secret.elasticachePassword"
    value = random_password.elasticache.result
  }

  set {
    name  = "secret.secretKey"
    value = random_password.elasticache_secret_key.result
  }

  set {
    name  = "ingress.certificateArn"
    value = aws_acm_certificate_validation.color.certificate_arn
  }

  set {
    name  = "ingress.dnsHostname"
    value = local.custom_domain_name
  }

  depends_on = [
    module.eks,
    aws_eks_node_group.eks,
    null_resource.color_image,
    kubernetes_namespace.color,
    helm_release.aws_loadbalancer_controller,
    helm_release.external_dns
  ]
}
