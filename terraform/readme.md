# Set up cloud infrastructure on AWS 

inspired by the excellent work of Sebastian Alvis https://github.com/pangeo-data/terraform-deploy !

This folder contains and Infrastructure-as-code (IaC)  definition of computing resources for running a jupyterhub server during a hackweek.

You'll need to install [terraform](https://www.terraform.io) for IaC and [sops](https://github.com/mozilla/sops) for encrypting sensative information. On a mac you can run:
```
brew install tfenv sops
tfenv install 0.13.6
tfenv use 0.13.6
```

You'll also need an [AWS Account](https://aws.amazon.com). If you're a researcher you can sign up for an account with [research credits](https://aws.amazon.com/government-education/research-and-technical-computing/cloud-credit-for-research/). Instructions here assume that you have Administrator privledges on your account and have set up the AWS command-line-interface [AWS CLI](https://aws.amazon.com/cli/).


**Warning** running terraform will create resources on your cloud account that do cost money. The jupyterhub infrastructure is minimal, such that with low usage you'd only be charged about $1 / day. 


### Best practices with Cloud accounts

Treat your Cloud account just like a bank account (in fact most accounts are backed by credit cards), and be very careful with your access keys and permissions! We follow guidelines for best-practices here by creating a dedicated 'bot' user that only has permissions to do setup our jupyterhub infrastructure rather than setting everythin up with our personal user account with full administrator access.

AWS has the security concepts of "Roles" and "Policies" for restricting access to cloud resources.

We create a user `github-actions-user` who by default can't do anything on our account. We then create a Role "github-actions-role" that our bot user (or other users in our account) can assume. It is the Role that has permissions "Policies" attached to it, and these policies allow us to do things that cost money like create EC2 instances, S3 buckets, and EKS cluster.

This repository also contains a GitHub Action that will automatically deploy infrastructure changes. To do this we add our `github-actions-user` access keys as repository secrets as described here - https://github.com/aws-actions/configure-aws-credentials. NOTE the repository secrets are encrypted and don't show up in logs so they are theoretically safe, but it is much better to use our bot user access keys here and NOT your admin keys. That way in the worst case scenario that the keys are leaked, someone with the keys would still only have limited access to your account.
