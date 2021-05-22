
This project spins up a decent EKS cluster for demos, development, or testing. In theory, you could scale it up to production too.

It currently features:

* Custom VPC Setup
* Kubernetes 1.20.
* Secrets Encryption via a KMS key.
* Control Plane logging to Cloudwatch.
* Common Tagging across all created resources for easy billing resolution.
* Calico networking instead of "aws-node"
* EC2 Workers with encrypted root volumes.
* 2 Helm Charts:
    * [Cluster-Autoscaler](https://github.com/kubernetes/autoscaler) for autoscaling
    * [AWS's Node Termination Handler](https://github.com/aws/aws-node-termination-handler) to watch for Spot instances being terminiated and draining them, rebalancing requests, and scheduled event draining
* Configurable ausoscaling EC2 Pools. By default it runs:
    * 1 t3.small instance for safety.  The autoscaler pod should run here.
    * 1 to 5 t3.medium spot instances.  Ideally, most of the workload should run on these. The spot price is set to the on-demand price.
* Configurable mapping of accounts, IAM roles, and IAM users to the aws-auth conifgmap
* Bleeding edge compatibility with Terraform 15
