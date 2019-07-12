# Jenkins on EKS

A complete example for spinning up Jenkins on EKS using Terraform, Packer, and Helm.

## Prerequisites

* [Terraform](https://www.terraform.io)
* [Packer](https://www.packer.io)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Helm](https://helm.sh)
* AWS account with permissions to create networking, compute, EKS, DNS infrastructure

## TL;DR

Spin up everything in one go:

```console
./apply.sh
```

**Note:** Terraform will prompt you for a domain.
Under this domain, a subdomain `jenkins` will be created.

## Infrastructure

Infrastructure code is separated into Packer and Terraform.
The Terraform code itself is split up into multiple modules.
Common Terraform code lives in `infra/terraform/common` and is symlinked into the individual Terraform modules.

### Bootstrapping

Terraform state is kept in an S3 bucket.
This bucket has to be created once upfront, which is also done with Terraform.
Obviously, the state for creating this bucket is kept locally.

```console
./infra/00_bootstrap.sh
```

### Creating

Terraform is used via the wrapper script `infra/terraform/terraform.sh` which configures environment variables and the backend.
In order to spin up the whole infrastructure run the following:

```console
./infra/apply.sh
```

## Kubernetes

Helm is used to deploy apps on the EKS cluster.
This includes the following:

* [kube2iam](https://github.com/helm/charts/tree/master/stable/kube2iam)
* [cert-manager](https://github.com/jetstack/cert-manager)
* [external-dns](https://github.com/helm/charts/tree/master/stable/external-dns)
* [cluster-autoscaler](https://github.com/helm/charts/tree/master/stable/cluster-autoscaler)
* [nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress)
* [TLS certificate](k8s/helm/charts/tls)
* [codecentric's Jenkins chart](https://github.com/codecentric/helm-charts/tree/master/charts/jenkins)

In order to deploy everything, run the following:

```console
./k8s/apply.sh
```
