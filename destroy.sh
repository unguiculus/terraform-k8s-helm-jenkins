#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -e "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")
readonly SCRIPT_DIR

main() {
    pushd "$SCRIPT_DIR" > /dev/null

    TF_VAR_domain=$(./infra/terraform/terraform_output.sh dns domain)
    export TF_VAR_domain

    ./k8s/destroy.sh
    delete_dns_records
    ./infra/destroy.sh

    popd > /dev/null
}

delete_dns_records() {
    local route53_zone_id
    route53_zone_id=$(./infra/terraform/terraform_output.sh dns route53_zone_id)

    local resource_record_sets
    resource_record_sets=$(aws route53 list-resource-record-sets --hosted-zone-id "$route53_zone_id" \
            --query "ResourceRecordSets[?Type != 'NS' && Type != 'SOA']" | jq --compact-output '.[]')

    if [[ -n "$resource_record_sets" ]]; then
        change_id=$(
            while read -r resource_record_set; do
                aws route53 change-resource-record-sets --hosted-zone-id "$route53_zone_id" \
                  --change-batch '{"Changes":[{"Action": "DELETE", "ResourceRecordSet": '"$resource_record_set"'}]}' \
                  --output text --query 'ChangeInfo.Id'
            done <<< "$resource_record_sets"
        )

        aws route53 wait resource-record-sets-changed --id "$change_id"
    fi
}

main
