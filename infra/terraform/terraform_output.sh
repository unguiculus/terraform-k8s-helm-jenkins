#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR

pushd "$SCRIPT_DIR" &> /dev/null

directory="${1?Specify module directory}"
output="${2?Specify output to retrieve from Terraform state}"

./terraform.sh --directory "$directory" output -no-color "$output"

popd &> /dev/null
