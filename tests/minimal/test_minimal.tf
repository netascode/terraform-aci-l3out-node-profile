terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "netascode/aci"
      version = ">=0.2.0"
    }
  }
}

resource "aci_rest" "fvTenant" {
  dn         = "uni/tn-TF"
  class_name = "fvTenant"
}

resource "aci_rest" "l3extOut" {
  dn         = "uni/tn-TF/out-L3OUT1"
  class_name = "l3extOut"
}

module "main" {
  source = "../.."

  tenant = "TF"
  l3out  = "L3OUT1"
  name   = "NP1"
}

data "aci_rest" "l3extLNodeP" {
  dn = module.main.dn

  depends_on = [module.main]
}

resource "test_assertions" "l3extLNodeP" {
  component = "l3extLNodeP"

  equal "name" {
    description = "name"
    got         = data.aci_rest.l3extLNodeP.content.name
    want        = module.main.name
  }
}
