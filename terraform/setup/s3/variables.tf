variable "region" {
  default = "us-west-2"
}

# Must not match an existing s3 bucket name
variable "bucket_name" {
  default = "terraform-hackweek-snowex"
}
