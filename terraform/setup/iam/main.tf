# Create IAM User for infrastructure management via GitHub Actions
# Also create a IAM Role so that other people can do things
# =======================
terraform {
  required_version = "~> 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-hackweek-snowex"
    key            = "hackweek-iam-user-config.tfstate"
    region         = "us-west-2"
    encrypt        = true
  }
}

provider "aws" {
  region      = var.region
}

data "aws_s3_bucket" "snowex" {
  bucket = "terraform-hackweek-snowex"
}

# To add tags
#data "aws_caller_identity" "current" {}

resource "aws_iam_user" "github-actor" {
  name = "github-actions-user"
}

resource "aws_iam_access_key" "github-actor" {
  user = aws_iam_user.github-actor.name
}

resource "aws_iam_policy" "github-actor" {
  name        = "github-actions-user-policy"
  description = "Allow github actions user to assume role"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ],
            "Resource": "${aws_iam_role.github-role.arn}",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "github-actor" {
  user       = aws_iam_user.github-actor.name
  policy_arn = aws_iam_policy.github-actor.arn
}

resource "aws_iam_role" "github-role" {
  name = "github-actions-role"
  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
			"Sid": "AllowIamUserAssumeRole",
			"Effect": "Allow",
			"Action": "sts:AssumeRole",
			"Principal": {
				"AWS": "${aws_iam_user.github-actor.arn}"
			}
		},
		{
			"Sid": "AllowPassSessionTags",
			"Effect": "Allow",
			"Action": "sts:TagSession",
			"Principal": {
				"AWS": "${aws_iam_user.github-actor.arn}"
			}
		}
	]
}
EOF
}

# Permisions for what the role can do once assumed
# Simple test: access ti files in a specific S3 bucket
resource "aws_iam_policy" "github-role" {
  name = "github-actions-role-s3policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${data.aws_s3_bucket.snowex.arn}",
        "${data.aws_s3_bucket.snowex.arn}/*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "github-role" {
  role = aws_iam_role.github-role.name
  policy_arn = aws_iam_policy.github-role.arn
}

# Attach an AWS-managed policy for doing anything with S3
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role = aws_iam_role.github-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# More advanced: all required EKS permissions (read from sidecar file)
resource "aws_iam_policy" "github-role-eks" {
  name = "github-actions-role-ekspolicy"
  policy = file("eks-permissions.json")
}

resource "aws_iam_role_policy_attachment" "github-role-eks" {
  role = aws_iam_role.github-role.name
  policy_arn = aws_iam_policy.github-role-eks.arn
}


resource "aws_kms_key" "sops-kms-key" {
  description         = "KMS Key for SOPS Encryption"
}

resource "aws_iam_policy" "github-role-sops" {
  name = "github-actions-role-sops"
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [{
		"Sid": "AllowUseOfSOPSKey",
		"Effect": "Allow",
		"Action": [
			"kms:Encrypt",
			"kms:Decrypt",
			"kms:ReEncrypt*",
			"kms:GenerateDataKey*",
			"kms:DescribeKey"
		],
		"Resource": "${aws_kms_key.sops-kms-key.arn}"
	}]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github-role-sops" {
  role = aws_iam_role.github-role.name
  policy_arn = aws_iam_policy.github-role-sops.arn
}
