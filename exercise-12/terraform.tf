terraform {
  required_version = "= 0.11.2"

  backend "s3" {
    bucket     = "terraform-training-state"
    key        = "gerrit.tfstate"
    region     = "eu-west-1"
  }
}
