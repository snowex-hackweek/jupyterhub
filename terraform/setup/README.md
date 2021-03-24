1. Create an S3 bucket to store Terraform remote state
```
cd s3
terraform init
terraform apply
```

1. Create an IAM Role that can be assumed by non-admins to do things
```
cd iam
terraform init
terraform apply
```
