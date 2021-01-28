variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-2"
}
variable "service_name" {
  type    = string
  default = "nodejs-app-test"
}
variable "service_description" {
  type    = string
  default = "My Test WebApp"
}
variable "load_balancer_type" {
  type    = string
  default = "application"
}
variable "solution_stack" {
  type    = string
  default = "64bit Amazon Linux 2 v5.2.4 running Node.js 12"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "beanstalk_service_role" {
    name = "beanstalk-service-role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "elasticbeanstalk"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "beanstalk_ec2_role" {
    name = "beanstalk-ec2-role"
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "beanstalk_service_profile" {
    name = "beanstalk-service-user"
    role = aws_iam_role.beanstalk_service_role.name
}

resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
    name = "beanstalk-ec2-user"
    role = aws_iam_role.beanstalk_ec2_role.name
}


resource "aws_iam_policy_attachment" "beanstalk_service_common" {
    name = "elastic-beanstalk-service"
    roles = [aws_iam_role.beanstalk_service_role.id]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

resource "aws_iam_policy_attachment" "beanstalk_service_health" {
    name = "elastic-beanstalk-service-health"
    roles = [aws_iam_role.beanstalk_service_role.id]
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_policy_attachment" "beanstalk_ec2_worker" {
    name = "elastic-beanstalk-ec2-worker"
    roles = [aws_iam_role.beanstalk_ec2_role.id]
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_policy_attachment" "beanstalk_ec2_web" {
    name = "elastic-beanstalk-ec2-web"
    roles = [aws_iam_role.beanstalk_ec2_role.id]
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_policy_attachment" "beanstalk_ec2_container" {
    name = "elastic-beanstalk-ec2-container"
    roles = [aws_iam_role.beanstalk_ec2_role.id]
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

#resource "aws_security_group" "alb-sg" {
#    name = "${var.service_name}-nsg"
#    ingress {
#    from_port = 80
#    to_port  = 80
#    protocol = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#    }

#    ingress {
#    from_port = 443
#    to_port  = 443
#    protocol = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#    description = "https"
#    }

#    egress {
#    from_port = 0
#    to_port = 0
#    protocol = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#    }
#}

#Application and Environment

resource "aws_elastic_beanstalk_application" "nodejs-webapp" {
  name        = var.service_name
  description = var.service_description
}

resource "aws_elastic_beanstalk_environment" "node-js-env" {
  name                = "nodejs-env"
  application         = aws_elastic_beanstalk_application.nodejs-webapp.name
  solution_stack_name = var.solution_stack

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "LoadBalancerType"
    value = var.load_balancer_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "LoadBalancerIsShared"
    value = "false"
  }

#  setting {
#    namespace = "aws:elbv2:loadbalancer"
#    name = "SecurityGroups"
#    value = aws_security_group.alb-sg.id
#  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "vpc-096e5a7b58ad054e3"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "subnet-01751847d52ca301f,subnet-09d9b29ed6883d131,subnet-0edf743bab2c8a797"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = "subnet-01751847d52ca301f,subnet-09d9b29ed6883d131,subnet-0edf743bab2c8a797"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBScheme"
    value = "public"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name = "Availability Zones"
    value = "Any 1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name = "MinSize"
    value = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name = "MaxSize"
    value = "1"
  }


  setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "ServiceRole"
        value     = aws_iam_role.beanstalk_service_role.name
  }

  setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = aws_iam_instance_profile.beanstalk_ec2_profile.name
  }  
}

