variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-west-2"
}

variable "port" {
  description = "The port where the load balancer will be publicly available in"
  type    = number
  default = 8080
}

variable "openfga_container_image" {
  description = "OpenFGA image to use"
  type        = string
  default     = "openfga/openfga:latest"

}

variable "service_count" {
  description = "Number of OpenFGA replicas to deploy"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "The number of CPU units to give each OpenFGA instance"
  type        = number
  default     = 256 # .25 vCPU
}

variable "task_memory" {
  description = "The amount of memory, in MB, to give each OpenFGA instance"
  type        = number
  default     = 512
}

variable "db_type" {
  description = "The storage backend to use. Valid values are `postgres` and `memory`."
  type        = string
  default     = "postgres"
}

variable "db_name" {
  type    = string
  default = "postgres"
}

variable "db_migrate" {
  description = "Enables a one-time run of the database migration"
  type        = bool
  default     = true
}

variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type    = string
  default = "postgres"
}

variable "db_min_capacity" {
  type    = number
  default = 0.5
}

variable "db_max_capacity" {
  type    = number
  default = 1.0
}

variable "additional_tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}