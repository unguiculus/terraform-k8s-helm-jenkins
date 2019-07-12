locals {
  worker_groups = [
    {
      instance_type         = var.instance_type
      ami_id                = data.aws_ami.eks.id
      subnets               = data.terraform_remote_state.networking.outputs.private_subnets
      asg_min_size          = "1"
      asg_desired_capacity  = "2"
      asg_max_size          = "3"
      asg_force_delete      = true
      autoscaling_enabled   = true
      protect_from_scale_in = true

      # Docker bridge must be enabled so we can mount the Docker socket into build pods
      bootstrap_extra_args = "--enable-docker-bridge true"
    },
  ]

  asg_names_string = join(" ", module.eks.workers_asg_names)
}
