# -----------------------------------------------------------------------------
# ECS task execution role (pull images, write logs)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_execution" {
  name = "${var.app_unique_id}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------------------------------------------------------
# ECS Express infrastructure role (manage ALB, auto-scaling, etc.)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_infrastructure" {
  name = "${var.app_unique_id}-ecs-infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_infrastructure" {
  name = "${var.app_unique_id}-ecs-infrastructure"
  role = aws_iam_role.ecs_infrastructure.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "application-autoscaling:*",
          "cloudwatch:*",
          "ecs:Describe*",
          "ecs:List*",
          "ecs:UpdateService",
          "ecs:CreateTaskSet",
          "ecs:DeleteTaskSet",
          "ecs:UpdateTaskSet",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "iam:PassRole",
          "route53:*",
        ]
        Resource = "*"
      },
    ]
  })
}
