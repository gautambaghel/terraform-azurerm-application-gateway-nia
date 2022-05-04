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

setup_az () {
    echo "export ARM_SUBSCRIPTION_ID=${arm_subscription_id}" >> set_env.sh
    echo "export ARM_TENANT_ID=${arm_tenant_id}" >> set_env.sh
    echo "export ARM_CLIENT_ID=${arm_client_id}" >> set_env.sh
    echo "export ARM_CLIENT_SECRET=${arm_client_secret}" >> set_env.sh
    source ./set_env.sh
}

setup_deps
setup_cts_files
setup_az

# Clone the repo to get the files
git clone --branch hashicups https://github.com/gautambaghel/terraform-azurerm-application-gateway-nia

mv cts-config-basic.hcl terraform-azurerm-application-gateway-nia/examples
mv cts-example-basic.tfvars terraform-azurerm-application-gateway-nia/examples

cd terraform-azurerm-application-gateway-nia/examples && consul-terraform-sync -config-file cts-config-basic.hcl