output "route53_zone_id" {
  value = aws_route53_zone.ci.id
}

output "domain" {
  value = var.domain
}
