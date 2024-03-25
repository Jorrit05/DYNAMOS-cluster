#!/bin/bash

# Define functions as variables to easily manage them
deploy_ingress_func='deploy_ingress() {
  coreChart="${DYNAMOS_ROOT}/charts/core"
  helm install -f "${coreChart}/ingress-values.yaml" nginx ingress-nginx/ingress-nginx -n ingress
}'

deploy_api_gateway_func='deploy_api_gateway() {
  apiGatewayChart="${DYNAMOS_ROOT}/charts/api-gateway/values.yaml"
  helm upgrade -i -f "${apiGatewayChart}" api-gateway ${DYNAMOS_ROOT}/charts/api-gateway --set hostPath="${DYNAMOS_ROOT}"
}'

deploy_core_func='deploy_core() {
  coreChart="${DYNAMOS_ROOT}/charts/core"
  helm upgrade -i -f "${coreChart}/values.yaml" core ${DYNAMOS_ROOT}/charts/core --set hostPath="${DYNAMOS_ROOT}"
}'

deploy_prometheus_func='deploy_prometheus() {
  coreChart="${DYNAMOS_ROOT}/charts/core"
  helm upgrade -i -f "${coreChart}/prometheus-values.yaml" prometheus prometheus-community/prometheus
}'

deploy_orchestrator_func='deploy_orchestrator() {
  orchestratorChart="${DYNAMOS_ROOT}/charts/orchestrator/values.yaml"
  helm upgrade -i -f "${orchestratorChart}" orchestrator ${DYNAMOS_ROOT}/charts/orchestrator --set hostPath="${DYNAMOS_ROOT}"
}'

deploy_agent_func='deploy_agent() {
  agentChart="${DYNAMOS_ROOT}/charts/agents/values.yaml"
  helm upgrade -i -f "${agentChart}" agent ${DYNAMOS_ROOT}/charts/agents
}'

restart_agent_func='restart_agent() {
  agentChart="${DYNAMOS_ROOT}/charts/agents/values.yaml"
  helm upgrade agent ${DYNAMOS_ROOT}/charts/agents --recreate-pods

  helm upgrade -i -f "${agentChart}" agent ${DYNAMOS_ROOT}/charts/agents
}'

deploy_surf_func='deploy_surf() {
  surfChart="${DYNAMOS_ROOT}/charts/thirdparty/values.yaml"
  helm upgrade -i -f "${surfChart}" surf ${DYNAMOS_ROOT}/charts/thirdparty
}'

delete_jobs_func='delete_jobs() {
  kubectl get pods -A | grep "jorrit-stutterheim" | awk "{split(\$2,a,\"-\"); print \$1\" \"a[1]\"-\"a[2]\"-\"a[3]}" | xargs -n2 bash -c "kubectl delete job \$1 -n \$0"
  etcdctl --endpoints=http://localhost:30005 del /agents/jobs/UVA/queueInfo/jorrit-stutterheim- --prefix
  etcdctl --endpoints=http://localhost:30005 del /agents/jobs/SURF/queueInfo/jorrit-stutterheim- --prefix
}'

uninstall_all_func='uninstall_all() {
  helm uninstall orchestrator
  helm uninstall surf
  helm uninstall agent
}'

deploy_all_func='deploy_all() {
  deploy_orchestrator
  deploy_agent
  deploy_surf
  deploy_api_gateway
}'

# Combine all function definitions into one variable
all_functions="$deploy_ingress_func
$deploy_api_gateway_func
$deploy_core_func
$deploy_prometheus_func
$deploy_orchestrator_func
$deploy_agent_func
$restart_agent_func
$deploy_surf_func
$delete_jobs_func
$uninstall_all_func
$deploy_all_func"

echo "DYNAMOS_ROOT="${HOME}/DYNAMOS"" >>~/.bashrc

# Check if function is already in .bashrc, if not, append it
for func in "$deploy_ingress_func" "$deploy_api_gateway_func" "$deploy_core_func" "$deploy_prometheus_func" "$deploy_orchestrator_func" "$deploy_agent_func" "$restart_agent_func" "$deploy_surf_func" "$delete_jobs_func" "$uninstall_all_func" "$deploy_all_func"; do
  func_name=$(echo "$func" | grep '()' | awk '{print $1}')
  if ! grep -q "$func_name" ~/.bashrc; then
    echo "$func" >>~/.bashrc
  fi
done

echo "Install brew and k9s"

sudo curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o install_brew.sh
sudo chmod +x install_brew.sh
./install_brew.sh

(
  echo
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
) >>/users/$USER/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
