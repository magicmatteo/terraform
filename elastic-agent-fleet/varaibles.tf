variable "enrolment-token" {
  description = "Enrolment token for Elastic Fleet (secret)"
  type        = string
}

variable "fleet-url" {
  description = "Fleet url to enrol"
  type        = string
}

variable "prefix" {
  description = "Prefix for created resources"
  type        = string
  default     = "elastic-agent"
}

variable "agent-username" {
  description = "Username for admin user on the agent VM"
  type        = string
  default     = "localadmin"
}

variable "vm-size" {
  description = "SKU for the vm size"
  type        = string
  default     = "Standard_B1s"
}