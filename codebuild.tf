# build image and push to ECR
resource "aws_codebuild_project" "tf-eks-build" {
  name          = "tf-eks-build"
  description   = "Terraform EKS Build"
  service_role  = aws_iam_role.tf-eks-pipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO"
      value = aws_ecr_repository.tf-eks-ecr.repository_url
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.AWS_REGION
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
#    environment_variable {
#      name  = "IMAGE_REPO_NAME"
#      value = aws_ecr_repository.demo.name
#    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = var.build_spec
  }

}

# staging deploy
resource "aws_codebuild_project" "tf-eks-deploy-staging" {
  name          = "tf-eks-deploy-staging"
  description   = "Terraform EKS Deploy"
  service_role  = aws_iam_role.tf-eks-pipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           =   "${data.aws_caller_identity.current.account_id}.${var.deploy_image}.${var.AWS_REGION}.amazonaws.com/${var.repo_name}:latest"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name = "EKS_NAMESPACE"
      value = "tf-eks-staging"
    }
    
    environment_variable {
      name  = "ECR_REPO"
      value = aws_ecr_repository.tf-eks-ecr.repository_url
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = var.deploy_spec
  }

}

# production deploy
resource "aws_codebuild_project" "tf-eks-deploy-prod" {
  name          = "tf-eks-deploy-prod"
  description   = "Terraform EKS Deploy"
  service_role  = aws_iam_role.tf-eks-pipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           =   "${data.aws_caller_identity.current.account_id}.${var.deploy_image}.${var.AWS_REGION}.amazonaws.com/${var.repo_name}:latest"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "EKS_NAMESPACE"
      value = "tf-eks-prod"
    }
    environment_variable {
      name  = "ECR_REPO"
      value = aws_ecr_repository.tf-eks-ecr.repository_url
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = var.deploy_spec
  }

}