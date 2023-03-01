resource "restapi_object" "app-service" {
  path = "/groups/${var.group_id[var.env]}/apps"
  data = jsonencode({
    name = "env-test",
    provider_region = "aws-ap-southeast-2",
    location ="AU",
    deployment_model ="LOCAL",
    environment ="",
    template_id ="sync.todo",
    data_source = {
      name = "env-test",
      type = "mongodb-atlas",
        config = {
          clusterName = "cluster01",
          readPreference = "primary",
          wireProtocolEnabled = true
        }
      }
  })
}

data "restapi_object" "api-key-auth-provider" {
  path = "/groups/${var.group_id[var.env]}/apps/${restapi_object.app-service.id}/auth_providers"
  search_key = "name"
  search_value = "api-key"
}

resource "restapi_object" "api-key-enable" {
  provider = restapi.no-object-return
  path = "/groups/${var.group_id[var.env]}/apps/${restapi_object.app-service.id}/auth_providers"
  object_id = data.restapi_object.api-key-auth-provider.id
  force_new = [ "disabled" ]

  data = jsonencode({
    "_id" = "${data.restapi_object.api-key-auth-provider.id}",
    name = "api-key",
    type = "api-key",
    disabled = false
  })
  update_method = "PATCH"
  update_path = "/groups/${var.group_id[var.env]}/apps/${restapi_object.app-service.id}/auth_providers/{id}"
  create_method = "PATCH"
  create_path = "/groups/${var.group_id[var.env]}/apps/${restapi_object.app-service.id}/auth_providers/{id}"
  
  destroy_method = "PUT"
  destroy_path = "/groups/${var.group_id[var.env]}/apps/${restapi_object.app-service.id}/auth_providers/{id}/disable"
}

resource "restapi_object" "api-key" {
  depends_on = [
    restapi_object.api-key-enable
  ]
  path = "/groups/${var.group_id[var.env]}/apps/${restapi_object.app-service.id}/api_keys"
  data = jsonencode({
    name = "inspections-api-key",
  }) 
}

output "api-key" {
  value = jsondecode(restapi_object.api-key.create_response)["key"]
}  