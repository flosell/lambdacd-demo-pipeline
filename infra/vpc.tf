resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/26"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "public_1" {
  cidr_block = "10.0.0.0/27"
  vpc_id = "${aws_vpc.default.id}"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id = "${aws_subnet.public_1.id}"
}
