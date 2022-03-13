terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws        = ">= 3.45.0"
    local      = ">= 2.1.0"
    random     = ">= 3.1.0"
    kubernetes = "~> 2.2.0"
    cloudinit  = "~> 2.2.0"
    null       = "~> 3.1.0"
  }
}
