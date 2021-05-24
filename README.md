# My AWS EKS

## Description

I couldn't find any example Terraform projects to make an EKS cluster that I was happy with, so I cobbled this one together.  This project spins up a decent EKS cluster for demos, development, or testing. In theory, you could scale it up to production too if your apps are stateful and can tolerate using spot instances - but it's really meant to be for short/medium term environments that you spin up or down at need.

It currently features:

* Custom VPC Setup.
* Kubernetes 1.20.
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
* Bleeding edge compatibility with Terraform 15.
* Generation of the Kubeconfig needed for kubectl, helm, etc.

## Key Aims

* Cost to remain as low as possible. 
* Ideally, I want this project to always run with the latest Terraform - though this requires compatibility with the public AWS terraform modules.
* Helm is the tool of choice for installing into the cluster - Convince me otherwise.

## Installation.

* This was last run with Terraform 0.15.4. 
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
