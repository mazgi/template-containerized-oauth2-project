variable "app_unique_id" {
  description = "Unique identifier used as a prefix for all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "base_domain_name" {
  description = "Base domain name for DNS zone (e.g. example.com). Zone: aws.{app_unique_id}.{base_domain_name}"
  type        = string
}
