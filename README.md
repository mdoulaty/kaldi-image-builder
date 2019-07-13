# Kaldi Docker Image Builder
This repository contains the codes needed for automating Kaldi's Docker image builds. It uses [Terraform](https://www.terraform.io/) to provision the required resources in the cloud to build and push the images to the container registary. Terraform is a provider agnostic tool and most of the major public and private cloud providers are supported. In this repository the examples are based on Microsoft Azure, but any other supported cloud provider can be used.

To build this sample, first rename `build-env.tfvars.empty` to `build-env.tfvars` and update the corresponding values. For Azure, please follow [these instructions](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure). 

## Building Docker images
To build the latest CPU-based image, run:
```bash
make cpu
```

It will provision a VM, install the required software to build Kaldi's CPU-based Docker image, then build and push them to Kaldi's repository in DockerHub and then clean up the resources. The default tag is `latest`, it can be changed by passing a `tag` parameter:
```bash
make tag=SOMETAG cpu
```

Similarly to build GPU-based images, run:
```bash
make gpu
```

To change the region, VM type and other settings or to use a different cloud provider, check `build-env.tf` files.
The important part for building and pushing the images is located in `provisioner "remote-exec"` section of the files.
