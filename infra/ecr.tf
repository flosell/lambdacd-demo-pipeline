resource "aws_ecr_repository" "lb" {
  name = "lambdacd-demo-lb"
}

resource "aws_ecr_repository" "pipeline" {
  name = "lambdacd-demo-pipeline"
}

