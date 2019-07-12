#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR

main() {
    pushd "$SCRIPT_DIR" > /dev/null

    ./infra/apply.sh
    ./k8s/apply.sh

    popd > /dev/null
}

main
