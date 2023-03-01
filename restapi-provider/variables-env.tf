variable "group_id" {
  type = map(string)
  default = {
    "dev" = "XXXX"
    "uat" = "XXXX"
    "prod"= "XXXX"
  }
}