#!/bin/bash

set -e
set -o pipefail
# Grab our libs
. "`dirname $0`/setup-lib.sh"

handle_error() {
    echo "Error occurred on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

$SETUP="/local/setup"

log "go to dir"
cd $SETUP

log "Cloning repository..."
if ! git clone https://github.com/Jorrit05/DYNAMOS.git; then
    echo "Failed to clone the repository."
    exit 1
fi


log "Setting up paths..."
dynamos_path="${PWD}/DYNAMOS"

# Charts
charts_path="${dynamos_path}/charts"
data_values_yaml="${charts_path}/data-values.yaml"
core_chart="${charts_path}/core"
namespace_chart="${charts_path}/namespaces"
orchestrator_chart="${charts_path}/orchestrator"
agents_chart="${charts_path}/agents"
ttp_chart="${charts_path}/thirdparty"

# Config
config_path="${dynamos_path}/configuration"
k8s_service_files="${config_path}/k8s_service_files"
etcd_launch_files="${config_path}/etcd_launch_files"

log "Generating RabbitMQ password..."
rabbit_pw=$(openssl rand -base64 12)
rabbit_definitions_file=${k8s_service_files}/definitions.json
# Hash password
hashed_pw=$($SUDO docker run --rm  rabbitmq:3-management rabbitmqctl hash_password $rabbit_pw)
actual_hash=$(echo "$hashed_pw" | cut -d $'\n' -f2)

log "Replacing tokens..."
cp ${k8s_service_files}/definitions_example.json ${rabbit_definitions_file}

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed
    sed -i '' "s|%PWD%|${PWD}|g" ${data_values_yaml}
    sed -i '' "s|%PASSWORD%|${actual_hash}|g" ${rabbit_definitions_file}
else
    # GNU sed
    sed -i "s|%PWD%|${PWD}|g" ${data_values_yaml}
    sed -i "s|%PASSWORD%|${actual_hash}|g" ${rabbit_definitions_file}
fi

log "Installing namespaces..."

# Install namespaces
helm upgrade -i -f ${namespace_chart}/values.yaml namespaces ${namespace_chart} --set secret.password=${rabbit_pw}

#Install prometheus
log "Installing Prometheus..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade -i -f "${core_chart}/prometheus-values.yaml" prometheus prometheus-community/prometheus

log "Installing NGINX..."
helm install -f "${core_chart}/ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress -n ingress --version 0.18.0

log "Installing DYNAMOS core..."
helm upgrade -i -f ${core_chart}/values.yaml core ${core_chart}  --set hostPath=${PWD}

# Install orchestrator layer
helm upgrade -i -f "${orchestrator_chart}/values.yaml" orchestrator ${orchestrator_chart}

log "Installing agents layer"
helm upgrade -i -f "${agents_chart}/values.yaml" agents ${agents_chart}

log "Installing thirdparty layer..."
helm upgrade -i -f "${ttp_chart}/values.yaml" surf ${ttp_chart}

log "Finished setting up DYNAMOS"

exit 0
