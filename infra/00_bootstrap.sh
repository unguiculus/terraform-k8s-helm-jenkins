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

    log_start 'Applying bootstrap infrastructure...'
    ./terraform.sh --init --directory 00_bootstrap apply -auto-approve
    log_end 'Finished applying bootstrap infrastructure.'

    popd > /dev/null
}

main
