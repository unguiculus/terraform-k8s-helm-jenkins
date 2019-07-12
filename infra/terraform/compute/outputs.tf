output "cluster_name" {
  value = var.cluster_name
}

output "worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}

output "agent_iam_role_arn" {
  value = aws_iam_role.agent.arn
}

output "external_dns_iam_role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "cert_manager_iam_role_arn" {
  value = aws_iam_role.cert_manager.arn
}

output "cluster_autoscaler_iam_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}
