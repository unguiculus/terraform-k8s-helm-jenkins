#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR

readonly TILLER_NAMESPACE=tiller
export TILLER_NAMESPACE

main() {
    # shellcheck source=../tools/tools.sh
    source "$SCRIPT_DIR/../tools/tools.sh"

    pushd "$SCRIPT_DIR" > /dev/null

    log_start 'Purging Helm charts...'

    helm delete --purge jenkins
    helm delete --purge nginx-ingress
    helm delete --purge cluster-autoscaler
    helm delete --purge external-dns
    helm delete --purge tls
    helm delete --purge cert-manager
    helm delete --purge kube2iam

    kubectl delete --filename https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

    log_end 'Finished purging Helm charts.'
    log_start 'Removing Tiller...'

    helm reset

    log_end 'Finished removing Tiller.'
    log_start 'Deleting namespaces...'

    kubectl delete namespaces jenkins
    kubectl delete namespaces ingress
    kubectl delete namespaces kube2iam

    log_start 'Finished deleting namespaces...'

    popd > /dev/null
}

main
