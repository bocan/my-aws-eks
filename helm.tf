resource "helm_release" "aws_node_termination_handler" {
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

resource "helm_release" "autoscaler" {
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


module "alb_controller" {
  source = "git::github.com/GSA/terraform-kubernetes-aws-load-balancer-controller?ref=v4.1.0"

  k8s_cluster_type = "eks"
  k8s_namespace    = "kube-system"
  aws_tags         = local.tags

  aws_region_name  = local.region
  k8s_cluster_name = local.cluster_name
  depends_on = [
    module.eks, null_resource.kube_config, null_resource.install_calico_plugin
  ]
  alb_controller_depends_on = [
    module.eks
  ]
}
