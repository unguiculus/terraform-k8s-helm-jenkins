data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = [module.eks.worker_iam_role_arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "agent" {
  name               = "${var.cluster_name}-agent"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = {
    Name = "${var.cluster_name}-agent"
  }
}

resource "aws_iam_role_policy_attachment" "agent" {
  role       = aws_iam_role.agent.id
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = {
    Name = "${var.cluster_name}-external-dns"
  }
}

resource "aws_iam_role_policy" "external_dns" {
  name   = "${var.cluster_name}-external-dns"
  role   = aws_iam_role.external_dns.id
  policy = data.aws_iam_policy_document.external_dns.json
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = "${var.cluster_name}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = {
    Name = "${var.cluster_name}-cert-manager"
  }
}

resource "aws_iam_role_policy" "cert_manager" {
  name   = "${var.cluster_name}-cert-manager"
  role   = aws_iam_role.cert_manager.id
  policy = data.aws_iam_policy_document.cert_manager.json
}

data "aws_iam_policy_document" "cert_manager" {
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = {
    Name = "${var.cluster_name}-cluster-autoscaler"
  }
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name   = "${var.cluster_name}-cluster-autoscaler"
  role   = aws_iam_role.cluster_autoscaler.id
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    effect    = "Allow"
    actions   = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
    resources = ["*"]
  }
}
