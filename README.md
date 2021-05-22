# My AWS EKS

## Description

I couldn't find any example Terraform projects to make an EKS cluster that I was happy with, so I cobbled this one together.  This project spins up a decent EKS cluster for demos, development, or testing. In theory, you could scale it up to production too.

It currently features:

* Custom VPC Setup.
* Kubernetes 1.20.
* Secrets Encryption via a KMS key.
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
* Bleeding edge compatibility with Terraform 15.
* Generation of the Kubeconfig needed for kubectl, helm, etc.

## Key Aims

* Cost to remain as low as possible. 
* Ideally, I want this project to always run with the latest Terraform - though this requires compatibility with the public AWS terraform modules.

## Installation.

* This was last run with Terraform 0.15.4. 
* Just edit what you need to in provider.tf to allow you to connect, and put what you want into local.tf 

## Todo

* I need to test the autoscaling in anger.
* The Autoscaler pod isn't tied to the on-demand node yet.
* Setup pre-commit tooling.
* I'd like to security scan all this in multiple tools. I've done it with Checkov and it's ok there.
* I wanted to use Launch Templates instead of Launch Configs - but there seems to be a bug in the EKS terraform modules where it's ignoring the Spot configuration.
* Testing Framework?
* Encryped Logs - I couldn't make it work at first.  Need to revisit this.
* Build a list of must-have Helm charts you'd tend to put into an EKS/K8S cluster.  I'm thinking it would start with, Vault, Prometheus (via its Operator), ???
