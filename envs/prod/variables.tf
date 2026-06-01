variable "env"     { type = string; default = "prod" }
variable "project" { type = string; default = "cybercheck" }

variable "region" {
  type    = string
  default = "eu-central-1"
  validation {
    condition     = startswith(var.region, "eu-")
    error_message = "NIS2 Art.28: region must be EU"
  }
}
