locals {
  static_routes = flatten([
    for node in var.nodes : [
      for sr in coalesce(node.static_routes, []) : {
        key = "${node.node_id}/${sr.prefix}"
        value = {
          node        = node.node_id
          prefix      = sr.prefix
          description = sr.description != null ? sr.description : ""
          preference  = sr.preference != null ? sr.preference : 1
        }
      }
    ]
  ])
  next_hops = flatten([
    for node in var.nodes : [
      for sr in coalesce(node.static_routes, []) : [
        for nh in coalesce(sr.next_hops, []) : {
          key = "${node.node_id}/${sr.prefix}/${nh.ip}"
          value = {
            static_route = "${node.node_id}/${sr.prefix}"
            ip           = nh.ip
            preference   = nh.preference != null ? nh.preference : 1
            type         = nh.type != null ? nh.type : "prefix"
          }
        }
      ]
    ]
  ])
}

resource "aci_rest" "l3extLNodeP" {
  dn         = "uni/tn-${var.tenant}/out-${var.l3out}/lnodep-${var.name}"
  class_name = "l3extLNodeP"
  content = {
    name = var.name
  }
}

resource "aci_rest" "l3extRsNodeL3OutAtt" {
  for_each   = { for node in var.nodes : node.node_id => node }
  dn         = "${aci_rest.l3extLNodeP.id}/rsnodeL3OutAtt-[topology/pod-${each.value.pod_id}/node-${each.value.node_id}]"
  class_name = "l3extRsNodeL3OutAtt"
  content = {
    rtrId         = each.value.router_id
    rtrIdLoopBack = each.value.router_id_as_loopback == false ? "no" : "yes"
  }
}

resource "aci_rest" "ipRouteP" {
  for_each   = { for item in local.static_routes : item.key => item.value }
  dn         = "${aci_rest.l3extRsNodeL3OutAtt[each.value.node].id}/rt-[${each.value.prefix}]"
  class_name = "ipRouteP"
  content = {
    ip    = each.value.prefix
    descr = each.value.description
    pref  = each.value.preference
  }
}

resource "aci_rest" "ipNexthopP" {
  for_each   = { for item in local.next_hops : item.key => item.value }
  dn         = "${aci_rest.ipRouteP[each.value.static_route].id}/nh-[${each.value.ip}]"
  class_name = "ipNexthopP"
  content = {
    nhAddr = each.value.ip
    pref   = each.value.preference
    type   = each.value.type
  }
}

resource "aci_rest" "l3extInfraNodeP" {
  for_each   = { for node in var.nodes : node.node_id => node if var.tenant == "infra" }
  dn         = "${aci_rest.l3extRsNodeL3OutAtt[each.key].id}/infranodep"
  class_name = "l3extInfraNodeP"
  content = {
    fabricExtCtrlPeering = "yes"
  }
}
