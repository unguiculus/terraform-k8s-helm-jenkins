resource "aws_route53_zone" "ci" {
  name = var.domain
}
