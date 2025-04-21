variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)  
}

variable "cluster_name" {
  type = string
  default = "sandbox"
}

variable "cluster_version" {
  type = string
  default = "1.32"
}

variable "k8s_zone_arn" {
  type = string
}

variable "github_ips" {
  type = list(string)
  default = [
    "192.30.252.0/22",
    "185.199.108.0/22",
    "140.82.112.0/20",
    "143.55.64.0/20",
  ]
}
