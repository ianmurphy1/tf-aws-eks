output "cluster_ca" {
  value = module.eks.cluster_certificate_authority_data  
}
