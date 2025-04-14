
data "terraform_remote_state" "rs_vpc-dev" {
  backend = "remote"

  config = {
    hostname = "ianm.scalr.io"
    organization = "env-v0opc1kall3u2gh4n"
    workspaces = {
      name = "vpc-dev"
    }
  }
}

locals {
    cidr_block = data.terraform_remote_state.rs_vpc-dev.outputs.cidr_block
    private_subnets = data.terraform_remote_state.rs_vpc-dev.outputs.private_subnets
    public_subnets = data.terraform_remote_state.rs_vpc-dev.outputs.public_subnets
    vpc_id = data.terraform_remote_state.rs_vpc-dev.outputs.vpc_id
}
