variable "region" { default = "tr-west-1" }
variable "access_key" {}
variable "secret_key" {}
variable "db_username" {
  default = "root"
}

variable "image_id" {
  default = "03418587-04d3-471c-a121-401f4e6af9bb"
}
variable "instance_password" {
  description = "Password for ECS instances"
  type        = string
  sensitive   = true
}
variable "instance_config_id" {
  description = "AS Configuration ID created manually from the Huawei Cloud Console"
  type        = string
}
variable "db_name" {
  type = string
}
variable "db_password" {
  type = string
  sensitive = true
}
variable "db_host" {
  description = "RDS endpoint"
  type = string
}