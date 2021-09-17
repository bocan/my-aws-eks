# My AWS EKS

## Description

I couldn't find any example Terraform projects to make an EKS cluster that I was happy with, so I cobbled this one together.  This project spins up a decent EKS cluster for demos, development, or testing. In theory, you could scale it up to production too if your apps are stateful and can tolerate using spot instances - but it's really meant to be for short/medium term environments that you spin up or down at need.

It currently features:

* Custom VPC Setup.
* Kubernetes 1.21.
* Secrets Encryption via a rotating customer-managed KMS key.
* Cloudwatch Encryption via a rotating customer-managed KMS key.
* Control Plane logging to Cloudwatch.
* Common Tagging across all created resources for easy billing resolution.
* Calico networking instead of "aws-node"
* EC2 worker nodes with encrypted root volumes.
* 2 Helm Charts:
    * [Cluster-Autoscaler](https://github.com/kubernetes/autoscaler) for autoscaling
    * [AWS's Node Termination Handler](https://github.com/aws/aws-node-termination-handler) to watch for Spot instances being terminiated and draining them, rebalancing requests, and scheduled event draining
* Configurable ausoscaling EC2 Pools. By default it runs:
    * 1 t3.small instance for safety.  The autoscaler pod should run here.
    * 1 to 5 t3.medium spot instances.  Ideally, most of the workload should run on these. The spot price is set to the on-demand price.
* Configurable mapping of accounts, IAM roles, and IAM users to the aws-auth conifgmap.
* (Occasionally) bleeding edge compatibility with Terraform 1.0.7
* Generation of the Kubeconfig needed for kubectl, helm, etc.

## Key Aims

* Cost to remain as low as possible. 
* Ideally, I want this project to always run with the latest Terraform - though this requires compatibility with the public AWS terraform modules.
* Helm is the tool of choice for installing into the cluster - Convince me otherwise.

## Installation.

* This was last run with Terraform 1.0.7
* Just edit what you need to in provider.tf to allow you to connect, and put what you want into local.tf 
* Run a terraform apply.

This is what ends up running after your first install:
```
╰─❯ kubectl get all -A
NAMESPACE     NAME                                                             READY   STATUS    RESTARTS   AGE
kube-system   pod/aws-node-termination-handler-2bjhv                           1/1     Running   0          113s
kube-system   pod/aws-node-termination-handler-vjjs9                           1/1     Running   0          113s
kube-system   pod/calico-kube-controllers-7f89f88c5b-8qtfm                     1/1     Running   0          119s
kube-system   pod/calico-node-92ssc                                            1/1     Running   0          119s
kube-system   pod/calico-node-mcps8                                            1/1     Running   0          119s
kube-system   pod/cluster-autoscaler-aws-cluster-autoscaler-6cf6577c6f-tllkp   1/1     Running   0          114s
kube-system   pod/coredns-996495cbb-sq9l4                                      1/1     Running   0          6m28s
kube-system   pod/coredns-996495cbb-ssp49                                      1/1     Running   0          6m28s
kube-system   pod/kube-proxy-6fqmt                                             1/1     Running   0          2m8s
kube-system   pod/kube-proxy-jqpt7                                             1/1     Running   0          2m4s

NAMESPACE     NAME                                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
default       service/kubernetes                                  ClusterIP   10.100.0.1      <none>        443/TCP         6m39s
kube-system   service/cluster-autoscaler-aws-cluster-autoscaler   ClusterIP   10.100.14.189   <none>        8085/TCP        115s
kube-system   service/kube-dns                                    ClusterIP   10.100.0.10     <none>        53/UDP,53/TCP   6m37s

NAMESPACE     NAME                                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/aws-node-termination-handler   2         2         2       2            2           kubernetes.io/os=linux   114s
kube-system   daemonset.apps/calico-node                    2         2         2       2            2           kubernetes.io/os=linux   2m
kube-system   daemonset.apps/kube-proxy                     2         2         2       2            2           <none>                   6m37s

NAMESPACE     NAME                                                        READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/calico-kube-controllers                     1/1     1            1           2m
kube-system   deployment.apps/cluster-autoscaler-aws-cluster-autoscaler   1/1     1            1           115s
kube-system   deployment.apps/coredns                                     2/2     2            2           6m37s

NAMESPACE     NAME                                                                   DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/calico-kube-controllers-7f89f88c5b                     1         1         1       2m
kube-system   replicaset.apps/cluster-autoscaler-aws-cluster-autoscaler-6cf6577c6f   1         1         1       115s
kube-system   replicaset.apps/coredns-996495cbb                                      2         2         2       6m28s
```

## Todo

* Add [an Ingress Controller](https://github.com/bocan/my-aws-eks/issues/5) - probably AWS Load Balancer Controller. 
* The Autoscaler pod isn't tied to the on-demand node yet.
* Setup pre-commit tooling, including a Checkov security scan.
* I wanted to use Launch Templates instead of Launch Configs - but there seems to be a bug in the EKS terraform modules where it's ignoring the Spot configuration.
* Testing Framework?
* Build a list of must-have Helm charts you'd tend to put into an EKS/K8S cluster.  I'm thinking it would start with:
    * Vault
    * Consul ?
    * Prometheus (via its Operator)
    * Cert Manager
    * Keycloak
* How can this integrate with Route53?  Should it?  

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.42.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | ~> 2.2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.2.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_template"></a> [template](#requirement\_template) | ~> 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.42.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_controller"></a> [alb\_controller](#module\_alb\_controller) | git::github.com/GSA/terraform-kubernetes-aws-load-balancer-controller?ref=v4.1.0 |  |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws |  |
| <a name="module_iam_assumable_role_admin"></a> [iam\_assumable\_role\_admin](#module\_iam\_assumable\_role\_admin) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc |  |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws |  |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_kms_alias.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.ekslogs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.ekslogs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [helm_release.autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.install_calico_plugin](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.kube_config](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Cloudwatch Log Group Name for this Cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_config_map_aws_auth"></a> [config\_map\_aws\_auth](#output\_config\_map\_aws\_auth) | A kubernetes configuration to authenticate to this EKS cluster. |
| <a name="output_kubectl_config"></a> [kubectl\_config](#output\_kubectl\_config) | kubectl config as generated by the module. |
| <a name="output_region"></a> [region](#output\_region) | AWS region. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

