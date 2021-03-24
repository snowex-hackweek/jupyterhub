[![Terraform](https://github.com/uwhackweek/jupyterhub-deploy/actions/workflows/Terraform.yml/badge.svg)](https://github.com/uwhackweek/jupyterhub-deploy/actions/workflows/Terraform.yml)
[![Helm](https://github.com/uwhackweek/jupyterhub-deploy/actions/workflows/Helm.yml/badge.svg)](https://github.com/uwhackweek/jupyterhub-deploy/actions/workflows/Helm.yml)

# jupyterhub-template
template repository for creating a jupyterhub for a uw hackweek

The goal of this repository is to define a 'canned' jupyterhub on AWS that is easy to deploy, modify, and scale to hundreds of simultaneous users.

1. infrastructure configuration in [./terraform](./terraform)
2. hub configuration in [./hub](./hub)
3. deployment is done automatically though GitHub Actions in [.github/workflows](.github/workflows)*
  * this requires adding access keys to repository secrets as decribed in the terraform readme file

### notes

This configuration assumes you're running one jupyterhub on a single EKS cluster, and don't necessarily plan to maintain the infrastructure for more than several months. If you want dependable infrastructure for longer time periods or don't want to set this up yourself, consider contracting https://2i2c.org. Below are reference links to more thorough documentation:

  - https://github.com/pangeo-data/terraform-deploy/tree/master/aws-examples
  - https://zero-to-jupyterhub.readthedocs.io/en/stable/
  - https://pilot.2i2c.org/en/latest/admin/howto/replicate.html
