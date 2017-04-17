resource "aws_iam_instance_profile" "demo_pipeline" {
  name = "demo_pipeline"
  roles = ["${aws_iam_role.demo_pipeline.name}"]
}

resource "aws_iam_role" "demo_pipeline" {
  name               = "demo-pipeline"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy_ec2.json}"
}

resource "aws_iam_role_policy_attachment" "demo_pipeline" {
  policy_arn = "${aws_iam_policy.ecr_pull_access.arn}"
  role       = "${aws_iam_role.demo_pipeline.name}"
}

resource "aws_iam_policy" "ecr_pull_access" {
  name   = "ecr_pull_access"
  policy = "${data.aws_iam_policy_document.ecr_pull_access.json}"
}

data "aws_iam_policy_document" "ecr_pull_access" {
  statement = {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:CompleteLayerUpload",
    ]

    resources = [
      "${aws_ecr_repository.pipeline.arn}",
      "${aws_ecr_repository.lb.arn}",
    ]
  }

  statement = {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "assume_role_policy_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
