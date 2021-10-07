# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this
project adheres to [Semantic Versioning](http://semver.org/).

<a name="v0.13.0"></a>
## [v0.13.0] - 2021-10-07
FEATURES:
- Convert ALB Load Balancer to a pure Helm chart rather than a module.
- Run with later Terraform
- Bump NGINX Controller
- Update Calico script

<a name="v0.12.0"></a>
## [v0.12.0] - 2021-06-14
FEATURES:
- Enabled ALB Load Balancer after successful testing
- Added ALB Ingress Examples
- Bump Kubernetes Version
- Run with later Terraform
- Bump NGINX Controller

<a name="v0.11.0"></a>
## [v0.11.0] - 2021-06-11
FEATURES:
- Use terraform provider default tags to automatically tag resources
- Support Terraform 1.0
- Enable VPC Flow logs to Cloudwatch

ADDED BUT DISABLED BY DEFAULT UNTIL TESTED:
- Add ALB Load Balancer Ingress Controller Helm Chart
- Add NGINX Ingressr Controller Helm Chart
- Add External DNS Helm Chart
- Add Certificate Manager Helm Chart


<a name="v0.10.0"></a>
## v0.10.0 - 2021-05-27
FEATURES:
- Add aws-load-balancer-controller ingress controller
- Adding changelog generation, version tools, and a Makefile for releases
- Add changelog generation tooling
- Enable changelog updating
- Enable pre-commit at Github
- Add pre-commit tooling, and update one tf module


[Unreleased]: https://github.com/bocan/my-aws-eks/compare/v0.12.0...HEAD
[v0.11.0]: https://github.com/bocan/my-aws-eks/compare/v0.10.0...v0.11.0
[v0.12.0]: https://github.com/bocan/my-aws-eks/compare/v0.11.0...v0.12.0
