provider "aws" {
  region      = "us-east-1"
  profile     = "tofu-app"
}

terraform {
 backend "s3" {
   bucket = "opentofu-state-files"
   key    = "tofu-state"
   region = "us-east-1"
   profile  = "tofu-app"
 }
}