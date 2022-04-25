#!/usr/bin/env bash
set -ex

setup_deps () {
    apt install -qy unzip curl jq git
    curl -O https://releases.hashicorp.com/consul-terraform-sync/${cts_version}+ent/consul-terraform-sync_${cts_version}+ent_linux_amd64.zip
    mkdir cts && cd cts/
    unzip consul-terraform-sync_${cts_version}+ent_linux_amd64.zip
    cp ./consul-terraform-sync /usr/local/bin/consul-terraform-sync
}

setup_cts_files () {
    echo "${cts_config}" | base64 -d > cts-config-basic.hcl
    echo "${cts_vars}" | base64 -d > cts-example-basic.tfvars
}

setup_deps
setup_cts_files

git clone https://github.com/gautambaghel/terraform-azurerm-application-gateway-nia

mv cts-config-basic.hcl terraform-azurerm-application-gateway-nia/examples
mv cts-config-basic.hcl terraform-azurerm-application-gateway-nia/examples

cd terraform-azurerm-application-gateway-nia/examples
consul-terraform-sync -config-file cts-config-basic.hcl