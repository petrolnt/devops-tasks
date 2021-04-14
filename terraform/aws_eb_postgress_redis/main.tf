

# pull in the dns zone
data "aws_route53_zone" "dns_zone" {
  name         = var.dns_domain
}

data "aws_elastic_beanstalk_hosted_zone" "current" {}

provider "aws" {
  region = var.aws_region
}

# VPC creation
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2"

  name = var.env_name
  cidr = var.rds_vpc_cidr

  azs              = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets
  create_database_subnet_group = var.create_db_subnet_group

  tags = var.tags
}

# Redis creation
module "redis" {
  source = "../modules/aws_redis"
  subnet_ids = module.vpc.private_subnets
  vpc = module.vpc.vpc_id
}

# Database creation
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3"

  name        = var.env_name
  description = "${var.env_name} database security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = var.db_port
      to_port     = var.db_port
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = var.tags
}

################################################################################
# RDS Module
################################################################################

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.env_name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = var.db_engine_version
  family               = var.db_family
  major_engine_version = var.db_major_engine_version
  instance_class       = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = var.db_storage_encrypted

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  name     = "foundation"
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  multi_az               = false
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_group.this_security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = var.db_deletion_protection

  #performance_insights_enabled          = true
  #performance_insights_retention_period = 7
  #create_monitoring_role                = true
  #monitoring_interval                   = 60

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = var.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
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

#Creating certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = format("%s%s%s", var.service_name, ".",  data.aws_route53_zone.dns_zone.name)
  validation_method = "DNS"
  tags = {
    Name = format("%s%s", var.service_name, " Terraform managed certificate")
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dvo_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = data.aws_route53_zone.dns_zone.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "cert_val" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dvo_record : record.fqdn]
}

########

#Application and Environment

resource "aws_elastic_beanstalk_application" "webapp" {
  name        = var.service_name
  description = var.service_description
}

resource "aws_elastic_beanstalk_environment" "eb-env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.webapp.name
  # Available solutions: aws elasticbeanstalk list-available-solution-stacks
  #solution_stack_name = var.solution_stack
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.12.5 running Ruby 2.6 (Passenger Standalone)"

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

  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }
  
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = aws_acm_certificate.cert.arn
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = module.vpc.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", module.vpc.public_subnets)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    #value = var.app_subnets
    value     = join(",", module.vpc.public_subnets)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBScheme"
    value = "public"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name = "Availability Zones"
    value = var.app_availability_zones
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name = "MinSize"
    value = var.app_min_size
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name = "MaxSize"
    value = var.app_max_size
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

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = var.app_instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = var.ssh_key
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "REDIS_ENDPOINT"
    value = module.redis.node_address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "POSTGRESQL_HOST"
    value = module.db.this_db_instance_endpoint
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "POSTGRESQL_USERNAME"
    value = module.db.this_db_instance_username
    }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "POSTGRESQL_PASSWORD"
    value = module.db.this_db_instance_password
    }

}

#DNS Alias
resource "aws_route53_record" "dns_alias" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = format("%s%s%s", var.service_name, ".",  data.aws_route53_zone.dns_zone.name)
  type    = "A"
  alias {
    name    = aws_elastic_beanstalk_environment.eb-env.cname
    zone_id = data.aws_elastic_beanstalk_hosted_zone.current.id
    evaluate_target_health = false
  }
}

output "resourse_dns_name" {
    value = aws_route53_record.dns_alias.name
    description = "Resourse FQDN"
}
