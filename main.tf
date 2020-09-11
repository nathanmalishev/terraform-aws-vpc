
########################
## Required variables ##
########################

variable "vpc_name" {
    description = "The name of the VPC. Best not to include non-alphanumeric characters."
}

variable "vpc_region" {
    description = "Target region for the VPC"
}

#########
## VPC ##
#########

# The VPC contains six subnets, three public and three private, one
# for each availability zone. Instances in the private subnets can
# communicate with the outside via a NAT instance.

resource "aws_vpc" "main" {
    
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    
    tags = {
        Name = "${var.vpc_name}"
        ManagedBy = "terraform"
    }


}

#####################
## Private Subnets ##
#####################

resource "aws_subnet" "private_1" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}a"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = false

    tags = {
        Name = "${var.vpc_name}-Private Subnet 1"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }


}

resource "aws_subnet" "private_2" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}b"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = false

    tags = {
        Name = "${var.vpc_name}-Private Subnet 2"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }


}

resource "aws_subnet" "private_3" {

    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}c"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = false
    
    tags = {
        Name = "${var.vpc_name}-Private Subnet 3"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

    
}

####################
## Public Subnets ##
####################

resource "aws_subnet" "public_1" {
    
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}a"
    cidr_block = "10.0.11.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.vpc_name}-Public Subnet 1"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }


}

resource "aws_subnet" "public_2" {
    
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}b"
    cidr_block = "10.0.22.0/24"
    map_public_ip_on_launch = true
    
    tags = {
        Name = "${var.vpc_name}-Public Subnet 2"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }


}

resource "aws_subnet" "public_3" {
    
    vpc_id = "${aws_vpc.main.id}"
    availability_zone = "${var.vpc_region}c"
    cidr_block = "10.0.33.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.vpc_name}-Public Subnet 3"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }


}
##################
## Internet Gateway ##
##################


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

#####################################
## Route tables: private instances ##
#####################################

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.public_1.id
  depends_on = [aws_internet_gateway.gw]
}


# Routes traffic through the NAT instance
resource "aws_route_table" "private_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }

    tags = {
        Name = "${var.vpc_name}-Private-Routing"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

}

# Subnet associations
# Private subnet 1
resource "aws_route_table_association" "private_a1" {

    subnet_id = "${aws_subnet.private_1.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

# Subnet associations
# Private subnet 2
resource "aws_route_table_association" "private_a2" {

    subnet_id = "${aws_subnet.private_2.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

# Subnet associations
# Private subnet 3
resource "aws_route_table_association" "private_a3" {

    subnet_id = "${aws_subnet.private_3.id}"
    route_table_id = "${aws_route_table.private_routes.id}"

}

####################################
## Route tables: public instances ##
####################################

# Routes through the internet gateway
resource "aws_route_table" "public_routes" {

    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags = {
        Name = "${var.vpc_name}-Public-Routing"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

}

# Subnet associations
# Public subnet 1
resource "aws_route_table_association" "public_a1" {

    subnet_id = "${aws_subnet.public_1.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

# Subnet associations
# Public subnet 2
resource "aws_route_table_association" "public_a2" {

    subnet_id = "${aws_subnet.public_2.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

# Subnet associations
# Public subnet 3
resource "aws_route_table_association" "public_a3" {

    subnet_id = "${aws_subnet.public_3.id}"
    route_table_id = "${aws_route_table.public_routes.id}"

}

#####################################
## VPC NAT instance security group ##
#####################################

resource "aws_security_group" "vpc_nat" {

    name = "${var.vpc_name}-NAT-Instance"
    description = "Allow outbound internet traffic from private subnet(s)"
    vpc_id = "${aws_vpc.main.id}"

    # Incoming traffic from private instances
    ingress  {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [
            "${aws_subnet.private_1.cidr_block}",
            "${aws_subnet.private_2.cidr_block}",
            "${aws_subnet.private_3.cidr_block}"
        ]
    }

    # NAT'ed outgoing traffic (passes through the VPC NAT instance)
    egress  {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.vpc_name}-NAT-Instance"
        VPC = "${var.vpc_name}"
        ManagedBy = "terraform"
    }

}

#############
## Outputs ##
#############

output "vpc_id" {
    value = "${aws_vpc.main.id}"
}

output "vpc_region" {
    value = "${var.vpc_region}"
}

output "vpc_private_subnets" {
    value = "${aws_subnet.private_1.cidr_block},${aws_subnet.private_2.cidr_block},${aws_subnet.private_3.cidr_block}"
}

output "vpc_private_subnet_ids" {
    value = [ "${aws_subnet.private_1.id}", "${aws_subnet.private_2.id}", "${aws_subnet.private_3.id}" ]
}

output "vpc_public_subnets" {
    value = "${aws_subnet.public_1.cidr_block},${aws_subnet.public_2.cidr_block},${aws_subnet.public_3.cidr_block}"
}

output "vpc_public_subnet_ids" {
    value = ["${aws_subnet.public_1.id}", "${aws_subnet.public_2.id}", "${aws_subnet.public_3.id}"]
}
