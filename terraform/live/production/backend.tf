terraform {
  backend "s3" {
    bucket                      = "gastro-api-opentofu-state"
    key                         = "production/opentofu.tfstate"
    region                      = "hel1"
    endpoint                    = "https://hel1.your-objectstorage.com"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_lockfile                = true
  }
}