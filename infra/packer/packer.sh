#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

: "${AWS_PROFILE:=default}"
export AWS_PROFILE
readonly AWS_PROFILE

: "${AWS_REGION:=eu-central-1}"
export AWS_REGION
readonly AWS_REGION

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR


main() {
    # shellcheck source=../../tools/tools.sh
    source "$SCRIPT_DIR/../../tools/tools.sh"

    pushd > /dev/null "$SCRIPT_DIR"

    log_start "Getting 'vpc_id' from Terraform state..."
    local vpc_id
    vpc_id=$(../terraform/terraform_output.sh networking vpc_id)
    echo "➟ $vpc_id"
    log_end "Finished getting 'vpc_id' from Terraform state."

    log_start "Getting 'subnet_id' from Terraform state..."
    local subnet_id
    subnet_id=$(../terraform/terraform_output.sh networking first_public_subnet)
    echo "➟ $subnet_id"
    log_end "Finished getting 'subnet_id' from Terraform state."

    log_start 'Runnig Packer...'
    packer build --var vpc_id="$vpc_id" --var subnet_id="$subnet_id" --var cluster_version=1.13 eks-ami.json
    log_end 'Finished runnig Packer.'

    popd > /dev/null
}

main
