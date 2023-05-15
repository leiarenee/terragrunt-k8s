data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}


################################################################################
# EKS Module
################################################################################


module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version         = "19.13.1"
  
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id  = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  cluster_addons = var.cluster_addons
  # cluster_addons = {
  #     coredns = {
  #     }
  #     kube-proxy = {
  #     }
  #     vpc-cni = {
  #     }
  #     aws-ebs-csi-driver = {
  #       service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
  #     }
      
  #   }

  # IAM Additional policies
  iam_role_additional_policies = var.iam_role_additional_policies

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults
   

  eks_managed_node_groups = var.eks_managed_node_groups

  # aws-auth configmap
  manage_aws_auth_configmap = var.manage_aws_auth_configmap

  aws_auth_roles = var.aws_auth_roles
  aws_auth_users = var.aws_auth_users
  aws_auth_accounts = var.aws_auth_accounts

  tags = var.tags

  node_security_group_additional_rules = var.node_security_group_additional_rules
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
}


################################################################################
# Supporting Resources
################################################################################


