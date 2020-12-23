#!/bin/bash
set -e

generate_awscli_kubeconfig() {
  aws_region=$(jq -r '.source.aws_region // ""' < $payload)
  aws_access_key_id=$(jq -r '.source.aws_access_key_id // ""' < $payload)
  aws_secret_access_key=$(jq -r '.source.aws_secret_access_key // ""' < $payload)
  
  if [ -z "$aws_region" ]; then
    echo "invalid payload (missing aws_region)"
    exit 1
  fi
  if [ -z "$aws_access_key_id" ]; then
    echo "invalid payload (missing aws_access_key_id)"
    exit 1
  fi
  if [ -z "$aws_secret_access_key" ]; then
    echo "invalid payload (missing aws_secret_access_key)"
    exit 1
  fi
  
  echo "using .aws config file..."
  export AWS_ACCESS_KEY_ID=$aws_access_key_id
  export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key 
  export AWS_DEFAULT_REGION=$aws_region
  export AWS_REGION=$aws_region
  echo "##############################################################################################################"
  echo "##############################################################################################################"
  echo "##################################### using creds ############################################################"
  echo "# AWS_ACCESS_KEY_ID = "$AWS_ACCESS_KEY_ID
  echo "# AWS_SECRET_ACCESS_KEY = "$AWS_SECRET_ACCESS_KEY
  echo "# AWS_DEFAULT_REGION = "$AWS_DEFAULT_REGION
  echo "# AWS_REGION = "$AWS_REGION
  echo "##############################################################################################################"
  echo "##############################################################################################################"
  echo "##############################################################################################################"
  local aws_eks_cluster_name
  aws_eks_cluster_name="$(jq -r '.source.aws_eks_cluster_name // ""' < "$payload")"
  aws eks update-kubeconfig --name $aws_eks_cluster_name
}


setup_kubernetes() {
  payload=$1
  source=$2
  generate_awscli_kubeconfig
  kubectl version
  return 0
}

wait_for_service_up() {
  SERVICE=$1
  TIMEOUT=$2
  if [ "$TIMEOUT" -le "0" ]; then
    echo "Service $SERVICE was not ready in time"
    exit 1
  fi
  RESULT=`kubectl get endpoints --namespace=$namespace $SERVICE -o jsonpath={.subsets[].addresses[].targetRef.name} 2> /dev/null || true`
  if [ -z "$RESULT" ]; then
    sleep 1
    wait_for_service_up $SERVICE $((--TIMEOUT))
  fi
}

setup_resource() {
  echo "Initializing kubectl..."
  setup_kubernetes $1 $2
  echo "setup done"
}
