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
          bfd         = sr.bfd
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
  bgp_peers = flatten([
    for node in var.nodes : [
      for peer in coalesce(node.bgp_peers, []) : {
        key = "${node.node_id}/${peer.ip}"
        value = {
          node                             = node.node_id
          ip                               = peer.ip
          remote_as                        = peer.remote_as
          description                      = peer.description
          allow_self_as                    = peer.allow_self_as
          as_override                      = peer.as_override
          disable_peer_as_check            = peer.disable_peer_as_check
          next_hop_self                    = peer.next_hop_self
          send_community                   = peer.send_community
          send_ext_community               = peer.send_ext_community
          password                         = peer.password
          allowed_self_as_count            = peer.allowed_self_as_count
          bfd                              = peer.bfd
          disable_connected_check          = peer.disable_connected_check
          ttl                              = peer.ttl
          weight                           = peer.weight
          remove_all_private_as            = peer.remove_all_private_as
          remove_private_as                = peer.remove_private_as
          replace_private_as_with_local_as = peer.replace_private_as_with_local_as
          unicast_address_family           = peer.unicast_address_family
          multicast_address_family         = peer.multicast_address_family
          admin_state                      = peer.admin_state
          local_as                         = peer.local_as
          as_propagate                     = peer.as_propagate
          peer_prefix_policy               = peer.peer_prefix_policy
          export_route_control             = peer.export_route_control
          import_route_control             = peer.import_route_control
        }
      }
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

resource "aci_rest_managed" "l3extLoopBackIfP" {
  for_each   = { for node in var.nodes : node.node_id => node if node.router_id_as_loopback == false && node.loopback != null }
  dn         = "${aci_rest_managed.l3extRsNodeL3OutAtt[each.key].dn}/lbp-[${each.value.loopback}]"
  class_name = "l3extLoopBackIfP"
  content = {
    addr = each.value.loopback
  }
}

resource "aci_rest_managed" "ipRouteP" {
  for_each   = { for item in local.static_routes : item.key => item.value }
  dn         = "${aci_rest_managed.l3extRsNodeL3OutAtt[each.value.node].dn}/rt-[${each.value.prefix}]"
  class_name = "ipRouteP"
  content = {
    ip     = each.value.prefix
    descr  = each.value.description
    pref   = each.value.preference
    rtCtrl = each.value.bfd == true ? "bfd" : ""
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

resource "aci_rest_managed" "bgpPeerP" {
  for_each   = { for item in local.bgp_peers : item.key => item.value }
  dn         = "${aci_rest_managed.l3extLNodeP.dn}/peerP-[${each.value.ip}]"
  class_name = "bgpPeerP"
  content = {
    addr             = each.value.ip
    descr            = each.value.description
    ctrl             = join(",", concat(each.value.allow_self_as == true ? ["allow-self-as"] : [], each.value.as_override == true ? ["as-override"] : [], each.value.disable_peer_as_check == true ? ["dis-peer-as-check"] : [], each.value.next_hop_self == true ? ["nh-sel"] : [], each.value.send_community == true ? ["send-com"] : [], each.value.send_ext_community == true ? ["send-ext-com"] : []))
    password         = each.value.password
    allowedSelfAsCnt = each.value.allowed_self_as_count
    peerCtrl         = join(",", concat(each.value.bfd == true ? ["bfd"] : [], each.value.disable_connected_check == true ? ["dis-conn-check"] : []))
    ttl              = each.value.ttl
    weight           = each.value.weight
    privateASctrl    = join(",", concat(each.value.remove_all_private_as == true ? ["remove-all"] : [], each.value.remove_private_as == true ? ["remove-exclusive"] : [], each.value.replace_private_as_with_local_as == true ? ["replace-as"] : []))
    addrTCtrl        = join(",", concat(each.value.unicast_address_family == true ? ["af-ucast"] : [], each.value.multicast_address_family == true ? ["af-mcast"] : []))
    adminSt          = each.value.admin_state == true ? "enabled" : "disabled"
  }

  lifecycle {
    ignore_changes = [content["password"]]
  }
}

resource "aci_rest_managed" "bgpAsP" {
  for_each   = { for item in local.bgp_peers : item.key => item.value }
  dn         = "${aci_rest_managed.bgpPeerP[each.key].dn}/as"
  class_name = "bgpAsP"
  content = {
    asn = each.value.remote_as
  }
}

resource "aci_rest_managed" "bgpLocalAsnP" {
  for_each   = { for item in local.bgp_peers : item.key => item.value if item.value.local_as != null }
  dn         = "${aci_rest_managed.bgpPeerP[each.key].dn}/localasn"
  class_name = "bgpLocalAsnP"
  content = {
    localAsn     = each.value.local_as
    asnPropagate = each.value.as_propagate
  }
}

resource "aci_rest_managed" "bgpRsPeerPfxPol" {
  for_each   = { for item in local.bgp_peers : item.key => item.value if item.value.peer_prefix_policy != null }
  dn         = "${aci_rest_managed.bgpPeerP[each.key].dn}/rspeerPfxPol"
  class_name = "bgpRsPeerPfxPol"
  content = {
    tnBgpPeerPfxPolName = each.value.peer_prefix_policy
  }
}

resource "aci_rest_managed" "bgpRsPeerToProfile_export" {
  for_each   = { for item in local.bgp_peers : item.key => item.value if item.value.export_route_control != null }
  dn         = "${aci_rest_managed.bgpPeerP[each.key].dn}/rspeerToProfile-[uni/tn-${var.tenant}/prof-${each.value.export_route_control}]-export"
  class_name = "bgpRsPeerToProfile"
  content = {
    tDn       = "uni/tn-${var.tenant}/prof-${each.value.export_route_control}"
    direction = "export"
  }
}

resource "aci_rest_managed" "bgpRsPeerToProfile_import" {
  for_each   = { for item in local.bgp_peers : item.key => item.value if item.value.import_route_control != null }
  dn         = "${aci_rest_managed.bgpPeerP[each.key].dn}/rspeerToProfile-[uni/tn-${var.tenant}/prof-${each.value.import_route_control}]-import"
  class_name = "bgpRsPeerToProfile"
  content = {
    tDn       = "uni/tn-${var.tenant}/prof-${each.value.import_route_control}"
    direction = "import"
  }
}
