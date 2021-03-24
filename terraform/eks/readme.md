# This contains a minimal autoscaling jupyterhub configuration

Deploy AWS EKS K8s cluster using the [terraform-eks-module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
```
terraform init
terraform apply
```

Takes ~20 min to deploy everything on your account.

Summary of things deployed:
- core nodegroup that runs a single machine 24/7 with your jupyterhub server 
- user nodegroup that scales up from 0 whenever someone logs into your jupyterhub

After successfully deploying things, navigate to the 'hub' folder to deploy your jupyterhub software on your fresh infrastructure
