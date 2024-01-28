#############################  Variables  #################################

variable "region" {
  default = "us-east-1"
}

variable "environment_name" {
  description = "Define environment_name for resources"
  type        = string
  default     = "studio-ghibli"
}


