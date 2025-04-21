resource "aws_security_group" "allow_tls" {
  name        = "allow-access-${var.cluster_name}"
  description = "Allow traffic from home and gihub webhook IPs"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow-access-${var.cluster_name}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "${local.current_ip}"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "${local.current_ip}"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_github" {
  for_each = { for ip in var.github_ips: ip => ip }

  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4 = "${each.value}"
  from_port = 443
  ip_protocol = "tcp"
  to_port = 443
}

resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  to_port           = 65535
  ip_protocol       = "tcp"
}
