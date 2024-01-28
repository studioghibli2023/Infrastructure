#############################  Variables  #################################

variable "region" {
  default = "us-east-1"
}

variable "environment_name" {
  description = "Define environment_name for resources"
  type        = string
  default     = "studio-ghibli"
}

variable "dynamodb_table" {
  description = "Define DynamoDB table"
  type        = string
  default     = "db_table"
}

variable "s3_bucket" {
  description = "Define DynamoDB table"
  type        = string
  default     = "my_s3_bucket"
}

