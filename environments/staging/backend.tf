terraform {
  backend "s3" {
    bucket  = "terformstatefile2026-077154311968-ap-south-1-an"
    key     = "statesave/staging/state.tfstate"
    region  = "ap-south-1"
    profile = "personal"
  }
}
