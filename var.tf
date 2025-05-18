variable "cluster_name" {
  description = "The ECS cluster name"
  default     = "imtech"
}
variable "service_name" {
  description = "The ECS service name"
  default     = "batel-logs"
}
variable "container_image" {
  description = "The Docker image to use for the container"
  default     = "314525640319.dkr.ecr.il-central-1.amazonaws.com/batel-repo:batel-nginx"
}
variable "desired_count" {
  description = "Desired number of running tasks"
  default     = 1
}
variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = ["subnet-088b7d937a4cd5d85"]
}
variable "execution_role_arn" {
  type    = string
  default = "arn:aws:iam::314525640319:role/ecsTaskExecutionRole"
}
variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
  default     = "sg-0ac3749215afde82a"
}
variable "target_group_name" {
  description = "Using existing target group"
  type        = string
  default     = "batel-tg"
}
variable "lb_name" {
    type    = string
    default = "imtec"
}
variable "elastic_search" {
  type    = string
  default = "172.30.20.131"
}

variable "log_stash" {
  type    = string
  default = "172.30.103.12"
  
}