data "template_cloudinit_config" "pipeline" {

  part {
    content_type = "text/cloud-config"
    content = "${var.cloudconfig_sshkeys}"
  }

  part {
    content_type = "text/cloud-config"
    content = <<EOF
#cloud-config
write_files:
- encoding: b64
  content: ${base64encode(file("${path.module}/../lb/haproxy.cfg"))}
  owner: root:root
  path: /etc/lambdacd-lb.cfg
  permissions: '0644'
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content = <<EOF
#!/bin/bash

set -e


curl --output /usr/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod +x /usr/bin/lein

yum install -y docker

chkconfig docker on
service docker restart

eval "$(aws ecr get-login --region eu-central-1)"

docker network create lambdacd --subnet 172.18.0.0/16

docker run --detach \
           --publish 8000:8000 \
           --network lambdacd \
           --name lambdacd-lb \
           --restart always \
           --volume /etc/lambdacd-lb.cfg:/usr/local/etc/haproxy/haproxy.cfg \
           haproxy:1.7-alpine

docker_group_id="$(grep ^docker /etc/group | cut -d: -f3)"

docker run --detach \
           --network lambdacd \
           --ip "172.18.0.10" \
           --name "pipeline-green" \
           --restart always \
           --volume /var/run/docker.sock:/var/run/docker.sock:rw \
           --group-add $${docker_group_id} \
           ${aws_ecr_repository.pipeline.repository_url}:latest

yum update -y

EOF
  }
}

resource "aws_security_group" "pipeline" {
  vpc_id = "${aws_vpc.default.id}"

  # ssh ingress
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # web egress
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # lambdacd-ui ingress
  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "pipeline" {
  ami = "${data.aws_ami.amazon_linux.id}"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.public_1.id}"

  user_data = "${data.template_cloudinit_config.pipeline.rendered}"

  security_groups = ["${aws_security_group.pipeline.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.demo_pipeline.id}"

  lifecycle {
    create_before_destroy = true
  }
}

output "public_ip" {
  value = "${aws_instance.pipeline.public_ip}"
}
