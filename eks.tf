data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  current_ip = "${chomp(data.http.myip.response_body)}/32"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name = var.cluster_name
  cluster_version = var.cluster_version
  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs = [
    "${local.current_ip}"
  ]

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  vpc_id = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    initial = {
      instance_types = [ "m7a.large" ]

      min_size = 1
      max_size = 5
      desired_size = 3
    }
  }

  node_security_group_additional_rules = {
    ingress_lb_access = {
      description = "Allow access from created home and github"
      protocol = "tcp"
      from_port = 0
      to_port = 65535
      type = "ingress"
      source_security_group_id = aws_security_group.allow_tls.id
    }
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_version = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  # Means it won't create the k8s resources but will create the
  # needed AWS resources. Doing this because terraform is fucking
  # shit at managing k8s resources
  create_kubernetes_resources = false

  # Add-ons
  enable_karpenter = true

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name_use_prefix = false
    role_name = "${var.cluster_name}-alb-controller"
  }

  enable_external_dns = true
  external_dns = {
    role_name_use_prefix = false
    role_name = "${var.cluster_name}-external-dns"
  }
  external_dns_route53_zone_arns = [
    "${var.k8s_zone_arn}"
  ]

  enable_cert_manager = true
  cert_manager = {
    role_name_use_prefix = false
    role_name = "${var.cluster_name}-cert-manager"
  }

  enable_external_secrets = true
  external_secrets = {
    role_name_use_prefix = false
    role_name = "${var.cluster_name}-external-secrets"
  }


  enable_argocd = true
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${module.eks.cluster_name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
