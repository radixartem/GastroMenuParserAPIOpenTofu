terraform {
  backend "s3" {
    bucket       = "gastro-api-opentofu-state"
    key          = "production/opentofu.tfstate"
    region       = "fsn1"
    endpoint     = "https://fsn1.your-objectstorage.com"   # замените на реальный endpoint
    use_lockfile = true
    # учётные данные передаются через переменные окружения AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
  }
}