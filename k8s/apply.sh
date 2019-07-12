#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

: "${AWS_REGION:=eu-central-1}"
export AWS_REGION
readonly AWS_REGION

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR

readonly TILLER_NAMESPACE=tiller
export TILLER_NAMESPACE

main() {
    # shellcheck source=../tools/tools.sh
    source "$SCRIPT_DIR/../tools/tools.sh"

    pushd "$SCRIPT_DIR" > /dev/null

    set_kubeconfig
    add_helm_repos
    update_helm_repos
    set_up_tiller
    install_charts

    popd > /dev/null
}

set_kubeconfig() {
    log_start 'Setting KUBECONFIG...'

    pushd "$SCRIPT_DIR/../infra" > /dev/null

    local cluster_name
    cluster_name=$(./terraform/terraform_output.sh compute cluster_name)

    KUBECONFIG="$(pwd)/terraform/compute/kubeconfig_$cluster_name"
    export KUBECONFIG

    popd > /dev/null

    log_end 'Finished setting KUBECONFIG.'
}

add_helm_repos() {
    log_start 'Adding Helm repositories...'

    helm repo add stable https://kubernetes-charts.storage.googleapis.com
    helm repo add codecentric https://codecentric.github.io/helm-charts
    helm repo add jetstack https://charts.jetstack.io

    log_end 'Finished adding Helm repositories.'
}

update_helm_repos() {
    log_start 'Updating Helm repositories...'

    helm repo update

    log_end 'Finished updating Helm repositories.'
}

set_up_tiller() {
    log_start 'Setting update Tiller...'

    kubectl create namespace "$TILLER_NAMESPACE" --dry-run --output yaml | kubectl apply --filename -
    kubectl apply --namespace "$TILLER_NAMESPACE" -f "$SCRIPT_DIR/manifests/tiller-rbac.yaml"

    helm init --service-account tiller --upgrade --wait \
        --override "spec.template.spec.containers[0].command={/tiller,--storage=secret}"

    log_end 'Finished setting update Tiller...'
}

install_charts() {
    log_start 'Installing Helm charts...'

    log_start 'Getting Terraform outputs...'

    pushd ../infra/terraform/ > /dev/null

    local worker_iam_role_arn
    worker_iam_role_arn=$(./terraform_output.sh compute worker_iam_role_arn)

    local cert_manager_iam_role_arn
    cert_manager_iam_role_arn=$(./terraform_output.sh compute cert_manager_iam_role_arn)

    local domain
    domain=$(./terraform_output.sh dns domain)

    local external_dns_iam_role_arn
    external_dns_iam_role_arn=$(./terraform_output.sh compute external_dns_iam_role_arn)

    local cluster_autoscaler_iam_role_arn
    cluster_autoscaler_iam_role_arn=$(./terraform_output.sh compute cluster_autoscaler_iam_role_arn)

    local cluster_name
    cluster_name=$(./terraform_output.sh compute cluster_name)

    local agent_iam_role_arn
    agent_iam_role_arn=$(./terraform_output.sh compute agent_iam_role_arn)

    popd > /dev/null

    log_end 'Finished getting Terraform outputs.'
    log_start 'Installing kube2iam...'

    pushd ./helm > /dev/null

    helm upgrade kube2iam stable/kube2iam --install --namespace kube2iam --wait \
        --version 1.0.1 \
        --values config/kube2iam_values.yaml \
        --set "extraArgs.base-role-arn=$worker_iam_role_arn"

    log_end 'Finished installing kube2iam.'
    log_start 'Installing cert-manager...'

    kubectl apply --filename https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
    helm upgrade cert-manager jetstack/cert-manager --install --namespace ingress \
        --version v0.8.1 \
        --values config/cert-manager_values.yaml \
        --set "podAnnotations.iam\.amazonaws\.com/role=$cert_manager_iam_role_arn"

    log_end 'Finished installing cert-manager.'
    log_start 'Installing tls...'

    helm upgrade tls ./charts/tls --install --namespace jenkins \
        --values config/tls_values.yaml \
        --set "jenkinsDomain=jenkins.$domain"

    log_end 'Finished installing tls.'
    log_start 'Installing nginx-ingress...'

    helm upgrade nginx-ingress stable/nginx-ingress --install --namespace ingress \
        --version 1.10.3 \
        --values config/nginx-ingress_values.yaml

    log_end 'Finished installing nginx-ingress.'
    log_start 'Installing external-dns...'

    helm upgrade external-dns stable/external-dns --install --namespace ingress \
        --version 1.7.5 \
        --values config/external-dns_values.yaml \
        --set "domainFilters[0]=${domain}." \
        --set "podAnnotations.iam\.amazonaws\.com/role=$external_dns_iam_role_arn"

    log_end 'Finished installing external-dns.'
    log_start 'Installing cluster-autoscaler...'

    helm upgrade cluster-autoscaler stable/cluster-autoscaler --install --namespace ingress \
        --version 0.14.2 \
        --values config/cluster-autoscaler_values.yaml \
        --set "awsRegion=$AWS_REGION" \
        --set "domainFilters[0]=${domain}." \
        --set "podAnnotations.iam\.amazonaws\.com/role=$cluster_autoscaler_iam_role_arn" \
        --set "autoDiscovery.clusterName=$cluster_name"

    log_end 'Finished installing cluster-autoscaler.'
    log_start 'Installing jenkins...'

    helm upgrade jenkins codecentric/jenkins --install --namespace jenkins \
        --version 1.4.1 \
        --values config/jenkins/jenkins_values.yaml \
        --set "jenkinsDomain=jenkins.$domain" \
        --set "ingress.annotations.external-dns\.alpha\.kubernetes\.io/hostname=jenkins.$domain" \
        --set "ingress.hosts[0]=jenkins.$domain" \
        --set "ingress.tls[0].secretName=tls-jenkins,ingress.tls[0].hosts[0]=jenkins.$domain" \
        --set "agentRoleArn=$agent_iam_role_arn" \
        --set-file plugins_txt=config/jenkins/plugins.txt \
        --set-file jenkins_yaml=config/jenkins/jenkins.yaml \
        --set-file init_groovy=config/jenkins/init.groovy \
        --set-file jobdsl_groovy=config/jenkins/jobdsl.groovy

    log_end 'Finished installing jenkins.'

    popd > /dev/null

    log_end 'Finished installing Helm charts.'
}

main
