#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

source "${SCRIPT_DIR}/validation-functions.sh"

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo "ibmcloud cli not found" >&2
  exit 1
fi

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

set -e

validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "values.yaml"

check_k8s_namespace "${NAMESPACE}"

#check_k8s_resource "${NAMESPACE}" "deployment" "${COMPONENT_NAME}"
if [[ ! -f "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

if [[ ! -f "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml" ]]; then
  echo "Application values not found - payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
  exit 1
fi

echo "Printing payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
cat "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"

count=0
until kubectl get namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || [[ $count -eq 20 ]]; do
  echo "Waiting for namespace: ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for namespace: ${NAMESPACE}"
  exit 1
else
  echo "Found namespace: ${NAMESPACE}. Sleeping for 30 seconds to wait for everything to settle down"
  sleep 30
fi

## Check if the icp4a-root-ca is there 
count=0
until kubectl get secret icp4a-root-ca -n "${NAMESPACE}" || [[ $count -eq 60 ]]; do
  echo "Waiting for secret icp4a-root-ca in ${NAMESPACE} COUNTER $count" 
  count=$((count + 1))
  sleep 60
done

if [[ $count -eq 60 ]]; then
  echo "Timed out waiting for icp4a-root-ca in ${NAMESPACE}"
  exit 1
fi

## Check if the admin.registrykey is there 
count=0
until kubectl get secret admin.registrykey -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
  echo "Waiting for secret admin.registrykey in ${NAMESPACE} COUNTER $count" 
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for admin.registrykey in ${NAMESPACE}"
  exit 1
fi

## Check if the subscription for ibm-automation is there 
SUBSNAME="ibm-automation"
count=0
#until kubectl get subs "${SUBSNAME}" -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
until kubectl get subs -n "${NAMESPACE}" |grep "${SUBSNAME}" || [[ $count -eq 20 ]]; do
  echo "Waiting for Subscription/${SUBSNAME} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for Subscription/${SUBSNAME} in ${NAMESPACE}"
  exit 1
fi

## Check if the configmaps is there 
count=0
until kubectl get configmaps icp4adeploy-cp4ba-access-info -n "${NAMESPACE}" || [[ $count -eq 60 ]]; do
  echo "Waiting for configmaps icp4adeploy-cp4ba-access-info in ${NAMESPACE} COUNTER $count" 
  count=$((count + 1))
  sleep 180
done

#### Temporary sleep to validate deployment manually
count=0
echo "Sleeping for 10 minutes after finding the subscription to manually verify"
sleep 600

cd ..
rm -rf .testrepo
