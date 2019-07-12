#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR

main() {
    # shellcheck source=../tools/tools.sh
    source "$SCRIPT_DIR/../tools/tools.sh"

    pushd ./infra/terraform > /dev/null

    log_start 'Destroying compute infrastructure...'
    ./terraform.sh --directory compute destroy -auto-approve
    log_end 'Finished destroying compute infrastructure.'

    log_start 'Destroying dns infrastructure...'
    ./terraform.sh --directory dns destroy -auto-approve
    log_end 'Finished destroying dns infrastructure.'

    log_start 'Destroying networking infrastructure...'
    ./terraform.sh --directory networking destroy -auto-approve
    log_end 'Finished destroying networking infrastructure.'

    popd > /dev/null
}

main
