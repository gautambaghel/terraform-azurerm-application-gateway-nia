#!/usr/bin/env bash
set -ex

setup_deps () {
    add-apt-repository universe -y
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    apt-get update -qy 
    apt-get install -qy consul-terraform-sync jq unzip git

    # azure cli
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
}

setup_cts_files () {
    echo "${cts_config}" | base64 -d > cts-config-basic.hcl
    echo "${cts_vars}" | base64 -d > cts-example-basic.tfvars
}

setup_deps
setup_cts_files

git clone --branch hashicups https://github.com/gautambaghel/terraform-azurerm-application-gateway-nia

mv cts-config-basic.hcl terraform-azurerm-application-gateway-nia/examples
mv cts-example-basic.tfvars terraform-azurerm-application-gateway-nia/examples

# Need to do az login here to proceed further
cd terraform-azurerm-application-gateway-nia/examples && consul-terraform-sync -config-file cts-config-basic.hcl