resource "aws_kms_key" "eks" {
  description         = "EKS Secret Encryption Key"
  enable_key_rotation = true
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.vpc_name}-eks-key-alias"
  target_key_id = aws_kms_key.eks.key_id
}


resource "aws_kms_key" "ekslogs" {
  description         = "EKS Log Group Encryption Key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.logging.json
}

resource "aws_kms_alias" "ekslogs" {
  name          = "alias/${local.vpc_name}-ekslogs-key-alias"
  target_key_id = aws_kms_key.ekslogs.key_id
}


data "aws_iam_policy_document" "logging" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:key/*"]
  }

  statement {
    sid    = "Allow CloudTrail to encrypt logs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:key/*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }

  statement {
    sid    = "Allow CloudTrail to describe key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow principals in the account to decrypt log files"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom"
    ]
    resources = ["arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:key/*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values = [
      "${data.aws_caller_identity.current.account_id}"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }

  statement {
    sid    = "Allow alias creation during setup"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kms:CreateAlias"]
    resources = ["arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:key/*"]
  }
}
