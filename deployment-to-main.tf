provider "aws" {
  alias  = "main"
  region = var.region
  default_tags {
    tags = local.default_tags
  }
  assume_role {
    role_arn = "arn:aws:iam::${var.main_account_id}:role/OrganizationAccountAccessRole"
  }
}

resource "aws_iam_role" "main-allow-deployment" {
  provider           = aws.main
  name               = "ApplicationDeployment"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "sts:AssumeRole",
        Principal = { "AWS" : "arn:aws:iam::${var.deployment_account_id}:root" }
      },
      {
        "Sid" : "AllowPassSessionTags",
        "Effect" : "Allow",
        "Action" : "sts:TagSession",
        "Principal" : { "AWS" : "arn:aws:iam::${var.deployment_account_id}:root" },
      }
    ]
  })
}

resource "aws_iam_policy" "main-deployment-permissions" {
  provider    = aws.main
  name        = "ApplicationDeployment"
  description = "Permissions necessary for deployment of infrastructure into Develop Account."
  policy      = file("deployment-policy.json")
}

resource "aws_iam_policy_attachment" "main-deployment-permissions" {
  provider   = aws.main
  name       = "Allowed Infrastructure Deployment"
  roles      = [aws_iam_role.main-allow-deployment.name]
  policy_arn = aws_iam_policy.main-deployment-permissions.arn
}

# Github OIDC Connector

module "github-oidc-main" {
  providers = {
    aws = aws.main
  }
  source    = "registry.terraform.io/unfunco/oidc-github/aws"
  version   = "0.4.0"

  github_organisation = "zbmowrey"
  github_repositories = ["zbmowrey-com", "repsales-net", "tomatowarning-com"]
  iam_role_name       = "GithubDeploymentRole"
  attach_admin_policy = true

}