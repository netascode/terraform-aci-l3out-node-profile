terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "CiscoDevNet/aci"
      version = ">=2.0.0"
    }
  }
}

resource "aci_rest_managed" "fvTenant" {
  dn         = "uni/tn-TF"
  class_name = "fvTenant"
}

resource "aci_rest_managed" "l3extOut" {
  dn         = "uni/tn-TF/out-L3OUT1"
  class_name = "l3extOut"
}

module "main" {
  source = "../.."

  tenant = "TF"
  l3out  = "L3OUT1"
  name   = "NP1"
  nodes = [{
    node_id               = 201
    pod_id                = 2
    router_id             = "2.2.2.2"
    router_id_as_loopback = false
    static_routes = [{
      prefix      = "0.0.0.0/0"
      description = "Default Route"
      preference  = 10
      next_hops = [{
        ip         = "3.3.3.3"
        preference = 10
        type       = "prefix"
      }]
    }]
  }]
}

data "aci_rest_managed" "l3extLNodeP" {
  dn = module.main.dn

  depends_on = [module.main]
}

resource "test_assertions" "l3extLNodeP" {
  component = "l3extLNodeP"

  equal "name" {
    description = "name"
    got         = data.aci_rest_managed.l3extLNodeP.content.name
    want        = module.main.name
  }
}

data "aci_rest_managed" "l3extRsNodeL3OutAtt" {
  dn = "${data.aci_rest_managed.l3extLNodeP.id}/rsnodeL3OutAtt-[topology/pod-2/node-201]"

  depends_on = [module.main]
}

resource "test_assertions" "l3extRsNodeL3OutAtt" {
  component = "l3extRsNodeL3OutAtt"

  equal "rtrId" {
    description = "rtrId"
    got         = data.aci_rest_managed.l3extRsNodeL3OutAtt.content.rtrId
    want        = "2.2.2.2"
  }

  equal "rtrIdLoopBack" {
    description = "rtrIdLoopBack"
    got         = data.aci_rest_managed.l3extRsNodeL3OutAtt.content.rtrIdLoopBack
    want        = "no"
  }
}

data "aci_rest_managed" "ipRouteP" {
  dn = "${data.aci_rest_managed.l3extRsNodeL3OutAtt.id}/rt-[0.0.0.0/0]"

  depends_on = [module.main]
}

resource "test_assertions" "ipRouteP" {
  component = "ipRouteP"

  equal "ip" {
    description = "ip"
    got         = data.aci_rest_managed.ipRouteP.content.ip
    want        = "0.0.0.0/0"
  }

  equal "descr" {
    description = "descr"
    got         = data.aci_rest_managed.ipRouteP.content.descr
    want        = "Default Route"
  }

  equal "pref" {
    description = "pref"
    got         = data.aci_rest_managed.ipRouteP.content.pref
    want        = "10"
  }
}

data "aci_rest_managed" "ipNexthopP" {
  dn = "${data.aci_rest_managed.ipRouteP.id}/nh-[3.3.3.3]"

  depends_on = [module.main]
}

resource "test_assertions" "ipNexthopP" {
  component = "ipNexthopP"

  equal "nhAddr" {
    description = "nhAddr"
    got         = data.aci_rest_managed.ipNexthopP.content.nhAddr
    want        = "3.3.3.3"
  }

  equal "pref" {
    description = "pref"
    got         = data.aci_rest_managed.ipNexthopP.content.pref
    want        = "10"
  }

  equal "type" {
    description = "type"
    got         = data.aci_rest_managed.ipNexthopP.content.type
    want        = "prefix"
  }
}
