#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC2016
instance_ids=$(aws ec2 describe-instances \
    --filter Name=tag:kubernetes.io/cluster/eks-ci-cluster,Values=owned \
    --query 'Reservations[*].Instances[?State.Name==`running`].InstanceId' \
    --output text)

PS3='Select worker node to connect to: '
select instance_id in $instance_ids; do
    echo "Connecting to instance: $instance_id"
    aws ssm start-session --target="$instance_id"
    break
done
