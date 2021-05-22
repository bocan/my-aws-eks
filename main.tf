data "aws_availability_zones" "available" {}

resource "aws_kms_key" "eks" {
  description         = "EKS Secret Encryption Key"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.vpc_name}-eks-key-alias"
  target_key_id = aws_kms_key.eks.key_id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                   = local.vpc_name
  cidr                   = local.cidr
  azs                    = data.aws_availability_zones.available.names
  private_subnets        = [cidrsubnet(local.cidr, 8, 1), cidrsubnet(local.cidr, 8, 2), cidrsubnet(local.cidr, 8, 3)]
  public_subnets         = [cidrsubnet(local.cidr, 8, 4), cidrsubnet(local.cidr, 8, 5), cidrsubnet(local.cidr, 8, 6)]
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  enable_dns_support     = true
  tags                   = local.tags

  enable_dhcp_options        = true
  dhcp_options_domain_name   = "service.consul"
  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source                    = "terraform-aws-modules/eks/aws"
  cluster_name              = local.cluster_name
  cluster_version           = local.cluster_version
  subnets                   = module.vpc.private_subnets
  vpc_id                    = module.vpc.vpc_id
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  enable_irsa               = true

  # This fixes a bug.  There currently isn't a 1.20 windows.  Only Linux
  worker_ami_name_filter_windows = "*"

  tags = local.tags

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]
  worker_groups = [
    {
      name                = "on-demand-1"
      root_encrypted      = true
      capacity_type       = "ON_DEMAND"
      instance_type       = local.on_demand_instance_type
      root_volume_size    = local.on_demand_root_volume_size
      asg_max_size        = local.on_demand_asg_max_size
      kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=normal"
      suspended_processes = ["AZRebalance"]
    },
    {
      name                = "spot-1"
      root_encrypted      = true
      capacity_type       = "SPOT"
      spot_price          = local.spot_price
      instance_type       = local.spot_instance_type
      root_volume_size    = local.spot_root_volume_size
      asg_max_size        = local.spot_asg_max_size
      kubelet_extra_args  = "--node-labels=node.kubernetes.io/lifecycle=spot"
      suspended_processes = ["AZRebalance"]
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    }
  ]
  map_roles    = local.map_roles
  map_users    = local.map_users
  map_accounts = local.map_accounts
}

resource "null_resource" "kube_config" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${local.region} --name ${local.cluster_name} --no-verify-ssl"
  }
  depends_on = [
    module.eks
  ]
}

resource "null_resource" "install_calico_plugin" {
  provisioner "local-exec" {
    command = "/bin/bash ./scripts/scripts.sh"
  }
  depends_on = [
    module.eks, null_resource.kube_config
  ]
}
