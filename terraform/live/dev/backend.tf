terraform {
  backend "s3" {
    bucket = "gastro-api-terraform-state"
    key = "dev/terraform.tfstate"
    region = "fsn1"
    endpoint = "https://fsn1.your-objectstorage.com"
    skip_credentials_validation = true
    skip_region_validation = true
    skip_requesting_account_id = true
    skip_metadata_api_check = true
  }
}
