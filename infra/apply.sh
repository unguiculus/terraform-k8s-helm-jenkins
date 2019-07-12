#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR

main() {
    # shellcheck source=../tools/tools.sh
    source "$SCRIPT_DIR/../tools/tools.sh"

    pushd "$SCRIPT_DIR/terraform" > /dev/null

    log_start 'Applying networking infrastructure...'
    ./terraform.sh --init --directory networking apply -auto-approve
    log_end 'Finished applying networking configuration.'

    log_start 'Building custom EKS AMI...'
    ../packer/packer.sh
    log_end 'Finished building custom EKS AMI.'

    log_start 'Applying dns infrastructure...'
    ./terraform.sh --init --directory dns apply -auto-approve
    log_end 'Finished applying dns infrastructure.'

    log_start 'Applying compute infrastructure...'
    ./terraform.sh --init --directory compute apply -auto-approve
    log_end 'Finished applying compute infrastructure.'

    popd > /dev/null
}

main
