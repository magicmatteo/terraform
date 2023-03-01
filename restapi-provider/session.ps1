$RestBody = @{ 
  username = $env:MONGODB_ATLAS_PUBLIC_KEY
  apiKey = $env:MONGODB_ATLAS_PRIVATE_KEY
}

$RestCall = @{
  Body = (ConvertTo-Json -InputObject $RestBody)
  Uri = 'https://realm.mongodb.com/api/admin/v3.0/auth/providers/mongodb-cloud/login'
  ContentType = 'application/json'
  Method = 'POST'
}

$RestMethodResult = Invoke-RestMethod @RestCall
return $RestMethodResult | ConvertTo-Json