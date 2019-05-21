# Kaldi Docker Image Builder
This repository contains the codes needed for automating Docker image builds. It uses [Terraform](https://www.terraform.io/) to provision required resources in the cloud to build and push the images. Terraform is provider agnostic tool and most of major public and private cloud providers are supported. In this repository the examples are based on Microsoft Azure, but any other supported cloud provider can be used.

To build this sample, first rename `build-env.tfvars.empty` to `build-env.tfvars` and update the corresponding values. For example for Azure, please follow the instructions from [here](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure). 

## Building Docker images
Simply run:
```bash
make cpu
```

It will provision a VM, install the required software to build Kaldi's CPU-based Docker image, then build and push them to Kaldi's repository in DockerHub.

Building GPU images is not yet supported.

