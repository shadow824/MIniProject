provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Owner       = "Abdelaziz Hamouda"
      Environment = "lab"
      ManagedBy   = "terraform"
    }
  }
}
