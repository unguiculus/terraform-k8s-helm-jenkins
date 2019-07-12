data "aws_ami" "eks" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["eks-ci-cluster-${var.cluster_version}-*"]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v5.0.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id  = data.terraform_remote_state.networking.outputs.vpc_id
  subnets = concat(data.terraform_remote_state.networking.outputs.private_subnets, data.terraform_remote_state.networking.outputs.public_subnets)

  worker_groups               = local.worker_groups
  workers_additional_policies = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]
}

// Workaround so workers and ASG can be deleted using 'terraform destroy'
// See https://github.com/terraform-aws-modules/terraform-aws-eks/issues/176#issuecomment-452363260
resource "null_resource" "eks-predestroy" {
  provisioner "local-exec" {
    when = destroy

    interpreter = ["/bin/bash", "-c"]

    command = <<EOF
for asg in ${local.asg_names_string}; do
    instance_ids=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg" --query AutoScalingGroups[].Instances[].InstanceId --output text)

    for instance in $instance_ids; do
        aws autoscaling set-instance-protection --instance-ids "$instance" --auto-scaling-group-name "$asg" --no-protected-from-scale-in
    done
done
EOF
  }
}

resource "null_resource" "test" {

  provisioner "local-exec" {
    command = "env | sort > env.txt"
  }

}
