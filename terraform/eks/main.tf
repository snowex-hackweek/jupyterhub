terraform {
  required_version = "~> 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.11"
    }
  }
  backend "s3" {
    bucket         = "terraform-hackweek-snowex"
    key            = "hackweek-eks-config.tfstate"
    region         = "us-west-2"
    encrypt        = true
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "aws" {
  region      = var.region
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "${local.cluster_name}-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names

  public_subnets       = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  private_subnets      = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.19"
  version         = "~> 13.0"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  enable_irsa     = true
  cluster_endpoint_private_access = true
  write_kubeconfig = false

  worker_groups_launch_template = [
    {
      name                    = "core-spot"
      asg_max_size            = 1
      asg_min_size            = 1
      asg_desired_capacity    = 1
      override_instance_types = ["t3.large", "t3a.large"]
      spot_instance_pools     = 2
      public_ip               = false
      subnets                 = [module.vpc.private_subnets[0]]

      # Use this to set labels / taints
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot,hub.jupyter.org/node-purpose=core"
    },
    {
      name                    = "user-spot"
      override_instance_types = ["m5.2xlarge", "m4.2xlarge", "m5a.2xlarge"]
      root_volume_type        = "gp3"
      spot_instance_pools     = 3
      asg_max_size            = 20
      asg_min_size            = 0
      asg_desired_capacity    = 0
      public_ip               = false
      subnets                 = [module.vpc.private_subnets[0]]


      # Use this to set labels / taints
      kubelet_extra_args = "--node-labels=node.kubernetes.io/lifecycle=spot,hub.jupyter.org/node-purpose=user --register-with-taints hub.jupyter.org/dedicated=user:NoSchedule"

      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/node-template/label/hub.jupyter.org/node-purpose"
          "propagate_at_launch" = "false"
          "value"               = "user"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/node-template/taint/hub.jupyter.org/dedicated"
          "propagate_at_launch" = "false"
          "value"               = "user:NoSchedule"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          "propagate_at_launch" = "false"
          "value"               = "true"
        }
      ]
    }
  ]
}
