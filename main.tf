locals {
  static_routes = flatten([
    for node in var.nodes : [
      for sr in coalesce(node.static_routes, []) : {
        key = "${node.node_id}/${sr.prefix}"
        value = {
          node        = node.node_id
          prefix      = sr.prefix
          description = sr.description
          preference  = sr.preference
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
            preference   = nh.preference
            type         = nh.type
          }
        }
      ]
    ]
  ])
}

resource "aci_rest_managed" "l3extLNodeP" {
  dn         = "uni/tn-${var.tenant}/out-${var.l3out}/lnodep-${var.name}"
  class_name = "l3extLNodeP"
  content = {
    name = var.name
  }
}

resource "aci_rest_managed" "l3extRsNodeL3OutAtt" {
  for_each   = { for node in var.nodes : node.node_id => node }
  dn         = "${aci_rest_managed.l3extLNodeP.dn}/rsnodeL3OutAtt-[topology/pod-${each.value.pod_id}/node-${each.value.node_id}]"
  class_name = "l3extRsNodeL3OutAtt"
  content = {
    rtrId         = each.value.router_id
    rtrIdLoopBack = each.value.router_id_as_loopback == true ? "yes" : "no"
  }
}

resource "aci_rest_managed" "ipRouteP" {
  for_each   = { for item in local.static_routes : item.key => item.value }
  dn         = "${aci_rest_managed.l3extRsNodeL3OutAtt[each.value.node].dn}/rt-[${each.value.prefix}]"
  class_name = "ipRouteP"
  content = {
    ip    = each.value.prefix
    descr = each.value.description
    pref  = each.value.preference
  }
}

resource "aci_rest_managed" "ipNexthopP" {
  for_each   = { for item in local.next_hops : item.key => item.value }
  dn         = "${aci_rest_managed.ipRouteP[each.value.static_route].dn}/nh-[${each.value.ip}]"
  class_name = "ipNexthopP"
  content = {
    nhAddr = each.value.ip
    pref   = each.value.preference
    type   = each.value.type
  }
}

resource "aci_rest_managed" "l3extInfraNodeP" {
  for_each   = { for node in var.nodes : node.node_id => node if var.tenant == "infra" }
  dn         = "${aci_rest_managed.l3extRsNodeL3OutAtt[each.key].dn}/infranodep"
  class_name = "l3extInfraNodeP"
  content = {
    fabricExtCtrlPeering = "yes"
  }
}
