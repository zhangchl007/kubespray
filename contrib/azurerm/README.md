# Kubernetes on Azure with Azure Resource Group Templates

Provision the base infrastructure for a Kubernetes cluster by using [Azure Resource Group Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates)

## Status

This will provision the base infrastructure (vnet, vms, nics, ips, ...) needed for Kubernetes in Azure into the specified
Resource Group. It will not install Kubernetes itself, this has to be done in a later step by yourself (using kubespray of course).

## Requirements

- [Install azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Login with azure-cli](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest)
- Dedicated Resource Group created in the Azure Portal or through azure-cli

## Configuration through group_vars/all

You have to modify at least two variables in group_vars/all. The one is the **cluster_name** variable, it must be globally
unique due to some restrictions in Azure. The other one is the **ssh_public_keys** variable, it must be your ssh public
key to access your azure virtual machines. Most other variables should be self explanatory if you have some basic Kubernetes
experience.

## Bastion host

You can enable the use of a Bastion Host by changing **use_bastion** in group_vars/all to **true**. The generated
templates will then include an additional bastion VM which can then be used to connect to the masters and nodes. The option
also removes all public IPs from all other VMs.

## Generating and applying

To generate and apply the templates, call:

```shell
./apply-rg.sh <resource_group_name>
```

If you change something in the configuration (e.g. number of nodes) later, you can call this again and Azure will
take care about creating/modifying whatever is needed.

## Clearing a resource group

If you need to delete all resources from a resource group, simply call:

```shell
./clear-rg.sh <resource_group_name>
```

**WARNING** this really deletes everything from your resource group, including everything that was later created by you!

## Installing Ansible and the dependencies

Install Ansible according to [Ansible installation guide](/docs/ansible/ansible.md#installing-ansible)

## Generating an inventory for kubespray

After you have applied the templates, you can generate an inventory with this call:

```shell
./generate-inventory.sh <resource_group_name>
```

It will create the file ./inventory which can then be used with kubespray, e.g.:

```shell
cd kubespray-root-dir
ansible-playbook -i contrib/azurerm/inventory -u devops --become -e "@inventory/sample/group_vars/all/all.yml" cluster.yml
```
## create all virtual machine and load balancer for K8S Installation

```shell
az group create --name k8s-azure-rg --location australiaeast

mkdir azure-k8s-deploy && cd azure-k8s-deploy

git clone https://github.com/kubernetes-incubator/kubespray.git

cd kubespray/contrib/azurerm/

./apply-rg.sh k8s-azure-rg
././generate-inventory.sh k8s-azure-rg

```
## Prepare basion for ansible playbook

```shell
python3 -m pip install --upgrade pip
pip install --user netaddr
pip install --user jinja2
pip install --user ansible==9.13.0
pip install --user jmespath

awk '/ip=/ {match($0, /^(\S+).*ip=([0-9.]+)/, a); if (a[1] && a[2]) print a[2], a[1]}' contrib/azurerm/inventory

ansible all -i inventory -m ping -u k8sdemo --ssh-common-args="-o StrictHostKeyChecking=no"

ansible all -i contrib/azurerm/inventory -u k8sdemo  -m ping

```

## install k8s cluster

```shell
ansible-playbook -i contrib/azurerm/inventory -u k8sdemo --become -e "@inventory/sample/group_vars/all/all.yml" cluster.yml

```
## Uninstall Calico CNI

```shell
 ansible-playbook -i contrib/azurerm/inventory -u k8sdemo --become remove-calico.yml

```
## Install Azure CNi and Reboot VMs

```shell
 ansible-playbook -i contrib/azurerm/inventory -u k8sdemo --become install-azure-cni.yml

 ansible all -i contrib/azurerm/inventory -u k8sdemo  -mshell -b -a "reboot"

 ```





