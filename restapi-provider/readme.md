# To Run

### 1. Add the environment variables required by the mongodb provider
```pwsh
$env:MONGODB_ATLAS_PUBLIC_KEY = "<PUB KEY>"
$env:MONGODB_ATLAS_PRIVATE_KEY = "<PRIV KEY>"
```

### 2. Set your 'env' variable (Defaults to dev)
```pwsh
$env = "dev"
```

### 3. Run Terraform
```pwsh
terraform init
terraform apply -var="env=$env"
terraform destroy -var="env=$env"
```