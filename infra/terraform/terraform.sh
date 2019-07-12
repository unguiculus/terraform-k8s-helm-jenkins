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

: "${TF_VAR_region:="$AWS_REGION"}"
export TF_VAR_region
readonly TF_VAR_region

export TF_VAR_remote_state_bucket=k8s-helm-jenkins-ci-cluster-state
readonly TF_VAR_remote_state_bucket

readonly TERRAFORM_VERSION=0.12.4

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR


show_help() {
cat << EOF
Usage: $(basename "$0") <options> <terraform args>
    -h, --help             Display help
    -v, --verbose          Display verbose output
    -d, --directory        The directory to execute Terraform in
    -i, --init             Run 'terraform init' before executing the actual command
EOF
}

main() {
    # shellcheck source=../../tools/tools.sh
    source "$SCRIPT_DIR/../../tools/tools.sh"

    local init=
    local directory=
    local verbose=

    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -d|--directory)
                if [[ -n "${2:-}" ]]; then
                    directory="$2"
                    shift
                else
                    log_error "'-d|--directory' cannot be empty."
                    exit 1
                fi
                ;;
            -i|--init)
                init=true
                ;;
            *)
                break
                ;;
        esac

        shift
    done


    if [[ -z "$directory" ]]; then
        log_error "'-d|--directory' is required."
        exit 1
    fi

    if [[ ! -d "$directory" ]]; then
        log_error "Folder '$directory' doesn't exist."
        exit 1
    fi

    module=$(realpath --relative-to="$SCRIPT_DIR" "$directory")

    [[ -n "$verbose" ]] && set -x

    pushd "$directory" > /dev/null

    if [[ -n "$init" ]]; then
        local args=()
        args+=(init)
        args+=(-reconfigure)
        args+=("-backend-config=key=$module")
        args+=("-backend-config=region=$TF_VAR_region")
        args+=("-backend-config=bucket=$TF_VAR_remote_state_bucket")
        args+=("-backend-config=dynamodb_table=${TF_VAR_remote_state_bucket}-lock")

        terraform "${args[@]}"
    fi

    terraform "$@"

    popd > /dev/null
}

main "$@"
