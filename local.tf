locals {
  region          = "eu-west-2"
  vpc_name        = "fu-labs"
  cluster_name    = "fu-labs-eks-cluster"
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
  spot_instance_type    = "t3.small"
  spot_root_volume_size = 20
  spot_asg_max_size     = 5
  spot_price            = "0.0472"

  #map_accounts = []
  map_accounts = ["894121584238"]

  # Additional IAM roles to add to the aws-auth configmap.
  #map_roles = []
  map_roles = [{ "rolearn" : "arn:aws:iam::894121584238:role/google-aws-role", "username" : "google-role", "groups" : ["system:masters"] }]

  # Additional IAM users to add to the aws-auth configmap.
  #map_users    = []
  map_users = [{ "userarn" : "arn:aws:iam::894121584238:user/chris", "username" : "chris", "groups" : ["system:masters"] }]
}

