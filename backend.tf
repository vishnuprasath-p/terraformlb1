terraform {
  backend "s3" {
    bucket = "primuslearning-app12"
    region = "us-east-1"
    key = "jenkins-server/terraform.tfstate"
  }
}