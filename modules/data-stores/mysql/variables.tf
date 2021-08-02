variable "identifier_prefix" {
  description = "ID prefix for database components"
  type = string
}

variable "name" {
  description = "Database name"
  type = string
}

variable "db_instance_class" {
  description = "Database server instance class"
  type = string
}

variable "allocated_storage" {
  description = "Amount of storage (GB) provisioned for DB"
  type = number
}