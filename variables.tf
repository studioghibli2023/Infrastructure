#############################  Variables  #################################

variable "region" {
  default = "us-east-1"
}

variable "environment_name" {
  description = "Define environment_name for resources"
  type        = string
  default     = "studio-ghibli"
}


variable "container_name" {
  description = "Define container name"
  type        = string
  default     = "studio-ghibli-container"
}


#enable for secure credentials
#variable "db-username" {
  #description = "Define database username"
  #type        = string
  #sensitive   = true
#}

#variable "db-password" {
  #description = "Define database password"
  #type        = string
 #sensitive   = true
#}