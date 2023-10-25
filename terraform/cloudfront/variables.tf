variable "env" {
  type = string
  default = "dev"
}

variable "feature" {
  type = string
  default = "master"
}

variable "context" {
  type = any
}

variable "config" {
  type = any
}

variable "tags" {
  type = any
}