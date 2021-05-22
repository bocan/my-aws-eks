locals {
  region          = "eu-west-2"
  vpc_name        = "chrisfu-labs"
  cluster_name    = "chrisfu-labs-eks-cluster"
  cidr            = "172.22.0.0/16"
  cluster_version = "1.20"
  tags = {
    "Owner"       = "Chris Funderburg"
    "Environment" = "Lab/Demo/Testing"
    "Managed-By"  = "Terraform"
  }
  k8s_service_account_name = "cluster-autoscaler-aws-cluster-autoscaler-chart"

  # On-Demand Pool
  on_demand_instance_type    = "t3.small"
  on_demand_root_volume_size = 20
  on_demand_asg_max_size     = 1

  # Spot Pool
  spot_instance_type    = "t3.medium"
  spot_root_volume_size = 20
  spot_asg_max_size     = 5
  spot_price            = "0.0472"

  #map_accounts = ["123456789012"]
  map_accounts = []

  # Additional IAM roles to add to the aws-auth configmap.
  #map_roles    = [{"rolearn": "arn:aws:iam::123456789012:role/MyRole", "username": "role1", "groups": ["system:masters"]}]
  map_roles = []

  # Additional IAM users to add to the aws-auth configmap.
  #map_users = [{ "userarn" : "arn:aws:iam::123456789012:user/chris.funderburg@wherever.com", "username" : "chrisfu", "groups" : ["system:masters"] }]
  map_users = []
}

