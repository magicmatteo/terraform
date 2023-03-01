// Set ENV Variables
// MONGODB_ATLAS_PUBLIC_KEY
// MONGODB_ATLAS_PRIVATE_KEY

provider "mongodbatlas" {}

data "external" "session" {
  program = [
    "pwsh",
    "${path.root}/session.ps1",
  ]
}

provider "restapi" {
  uri                  = "https://realm.mongodb.com/api/admin/v3.0/"
  debug                = true
  create_returns_object = true
  id_attribute = "_id"

  headers = {
    Authorization = "Bearer ${data.external.session.result["access_token"]}"
  }
}

provider "restapi" {
  uri                  = "https://realm.mongodb.com/api/admin/v3.0/"
  alias = "no-object-return"
  debug                = true
  write_returns_object = false
  
  id_attribute = "_id"

  headers = {
    Authorization = "Bearer ${data.external.session.result["access_token"]}"
  }
}
