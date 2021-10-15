###############################################################################
# AWS Node Termination Handler
# https://artifacthub.io/packages/helm/aws/aws-node-termination-handler
# https://github.com/aws/eks-charts/tree/master/stable/aws-node-termination-handler
# https://github.com/aws/aws-node-termination-handler
###############################################################################
resource "helm_release" "aws_node_termination_handler" {
  count = local.enable_termination_handler ? 1 : 0
  depends_on = [
    module.eks, null_resource.kube_config, null_resource.install_calico_plugin
  ]

  name       = "aws-node-termination-handler"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-node-termination-handler"

  set {
    name  = "awsRegion"
    value = local.region
  }
  set {
    name  = "enableSpotInterruptionDraining"
    value = "true"
  }
  set {
    name  = "enableRebalanceMonitoring"
    value = "true"
  }
  set {
    name  = "enableScheduledEventDraining"
    value = "true"
  }
  set {
    name  = "logLevel"
    value = "debug"
  }
}

###############################################################################
# Cluster Autoscaler
# https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler
#
###############################################################################
resource "helm_release" "autoscaler" {
  count = local.enable_autoscaler ? 1 : 0
  depends_on = [
    module.eks, null_resource.kube_config, null_resource.install_calico_plugin
  ]

  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"

  values = [
    templatefile(
      "${path.module}/templates/cluster-autoscaler-chart-values.yaml.tpl",
      { region       = local.region,
        svc_account  = local.k8s_service_account_name,
        cluster_name = local.cluster_name,
        role_arn     = module.iam_assumable_role_admin.iam_role_arn
      }
    )
  ]

}

###############################################################################
# ALB Ingress Controller
# https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
# https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller
# https://github.com/kubernetes-sigs/aws-load-balancer-controller
###############################################################################
module "alb_ingress_controller" {
  count  = local.enable_alb_ingress_controller ? 1 : 0
  source = "./modules/terraform-kubernetes-aws-load-balancer-controller"
  depends_on = [
    module.eks, null_resource.kube_config, null_resource.install_calico_plugin
  ]

  k8s_namespace = "kube-system"

  enable_host_networking                     = true
  aws_load_balancer_controller_chart_version = "1.2.7"

  aws_region_name  = local.region
  k8s_cluster_name = local.cluster_name
  alb_controller_depends_on = [
    module.eks
  ]
}

###############################################################################
# NGINX Ingress Controller
# https:// ADD PATH CHART INFO
###############################################################################
module "nginx-ingress-controller" {
  count  = local.enable_nginx_ingress_controller ? 1 : 0
  source = "lablabs/eks-ingress-nginx/aws"
  depends_on = [
    module.eks, null_resource.kube_config, null_resource.install_calico_plugin
  ]
  version            = "0.3.0"
  helm_chart_version = "3.35.0"
  k8s_namespace      = "kube-system"

  settings = { "controler.hostNetwork" = true }

}

module "external_dns" {
  count  = local.enable_external_dns ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-external-dns.git"
  depends_on = [
    module.eks, null_resource.kube_config, null_resource.install_calico_plugin
  ]
  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  helm_chart_version               = "5.0.2"

  settings = {
    "policy" = "upsert-only" # Modify how DNS records are sychronized between sources and providers.
  }
}

module "cert_manager" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-cert-manager.git"
  count  = local.enable_certificate_manager ? 1 : 0

  depends_on = [
    module.eks, null_resource.kube_config, null_resource.install_calico_plugin
  ]

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  dns01 = [
    {
      name           = "letsencrypt-staging"
      namespace      = "default"
      kind           = "ClusterIssuer"
      dns_zone       = "example.com"
      region         = local.region
      secret_key_ref = "letsencrypt-staging"
      acme_server    = "https://acme-staging-v02.api.letsencrypt.org/directory"
      acme_email     = "your@email.com"
    },
    {
      name           = "letsencrypt-prod"
      namespace      = "default"
      kind           = "ClusterIssuer"
      dns_zone       = "example.com"
      region         = local.region
      secret_key_ref = "letsencrypt-prod"
      acme_server    = "https://acme-v02.api.letsencrypt.org/directory"
      acme_email     = "your@email.com"
    }
  ]

  # In case you want to use HTTP01 challenge method uncomment this section
  # and comment dns01 variable
  # http01 = [
  #   {
  #     name           = "letsencrypt-staging"
  #     kind           = "ClusterIssuer"
  #     ingress_class  = "nginx"
  #     secret_key_ref = "letsencrypt-staging"
  #     acme_server    = "https://acme-staging-v02.api.letsencrypt.org/directory"
  #     acme_email     = "your@email.com"
  #   },
  #   {
  #     name           = "letsencrypt-prod"
  #     kind           = "ClusterIssuer"
  #     ingress_class  = "nginx"
  #     secret_key_ref = "letsencrypt-prod"
  #     acme_server    = "https://acme-v02.api.letsencrypt.org/directory"
  #     acme_email     = "your@email.com"
  #   }
  # ]

  # In case you want to create certificates uncomment this block
  # certificates = [
  #   {
  #     name           = "example-com"
  #     namespace      = "default"
  #     kind           = "ClusterIssuer"
  #     secret_name    = "example-com-tls"
  #     issuer_ref     = "letsencrypt-prod"
  #     dns_name       = "*.example.com"
  #   }
  # ]
}
