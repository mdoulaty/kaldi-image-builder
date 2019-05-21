variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "docker_hub_username" {}
variable "docker_hub_password" {}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    version         = "~> 1.28"
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
}

provider "random" {
    version = "~> 2.1"
}

provider "http" {
    version = "~> 1.1"
}

# Get IP address of the host (https://stackoverflow.com/questions/46763287/i-want-to-identify-the-public-ip-of-the-terraform-execution-environment-and-add)
data "http" "myip" {
    version = "~> 1.1"
    url     = "http://ipv4.icanhazip.com"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "KaldiBuildEnvironment"
    location = "eastus"

    tags {
        environment = "Kaldi"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "Kaldi"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Kaldi"
    }
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "${chomp(data.http.myip.body)}"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Kaldi"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Kaldi"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Kaldi"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS5_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "kaldivm"
        admin_username = "kaldi"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/kaldi/.ssh/authorized_keys"
            key_data = "${file("~/.ssh/id_rsa.pub")}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Kaldi"
    }

    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "kaldi"
            private_key = "${file("~/.ssh/id_rsa")}"
        }
        inline = [
            "sudo apt update",
            "sudo apt install -y git docker.io",
            "sudo mkdir /opt/kaldi",
            "sudo chown $USER:$USER /opt/kaldi",
            "git clone https://github.com/kaldi-asr/kaldi.git /opt/kaldi",
            "cd /opt/kaldi/docker/debian9.8-cpu/",
            "echo ${var.docker_hub_password} | sudo docker login -u ${var.docker_hub_username} --password-stdin",
            "sudo docker build --tag kaldiasr/kaldi:latest .",
            "sudo docker push kaldiasr/kaldi:latest",
    ]
    }
}

output "ip" {
        value = "${azurerm_public_ip.myterraformpublicip.ip_address}"
}
