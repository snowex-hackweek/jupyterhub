# IAM Role linked to K8s Service Account for User access to AWS resources (like S3)
module "iam_assumable_role_jovyan" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "jovyan-serviceaccount"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.hackweek-bucket-access-policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:jhub:jovyan"]
}

resource "aws_s3_bucket" "hackweek-data-bucket" {
  bucket = "${var.hackweek_name}-data"
  acl    = "private"
}

# bucket access policy
resource "aws_iam_policy" "hackweek-bucket-access-policy" {
    name        = "${var.hackweek_name}-data-bucket-access-policy"
    path        = "/"
    description = "Permissions for Terraform-controlled EKS cluster creation and management"
    policy      = data.aws_iam_policy_document.hackweek-bucket-access-permissions.json
}

# bucket access policy data
data "aws_iam_policy_document" "hackweek-bucket-access-permissions" {
  version = "2012-10-17"

  statement {
    sid       = "${var.hackweek_name}DataBucketListAccess"

    effect    = "Allow"

    actions   = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.hackweek-data-bucket.arn
    ]
  }

  statement {
    sid       = "${var.hackweek_name}DataBucketReadWriteAccess"

    effect    = "Allow"

    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.hackweek-data-bucket.arn}/*"
    ]
  }
}
