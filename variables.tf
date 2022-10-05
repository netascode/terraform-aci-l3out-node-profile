variable "tenant" {
  description = "Tenant name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{0,64}$", var.tenant))
    error_message = "Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `_`, `.`, `-`. Maximum characters: 64."
  }
}

variable "l3out" {
  description = "L3out name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{0,64}$", var.l3out))
    error_message = "Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `_`, `.`, `-`. Maximum characters: 64."
  }
}

variable "name" {
  description = "Node profile name."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{0,64}$", var.name))
    error_message = "Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `_`, `.`, `-`. Maximum characters: 64."
  }
}

variable "nodes" {
  description = "List of nodes. Allowed values `node_id`: 1-4000. Allowed values `pod_id`: 1-255. Default value `pod_id`: 1. Default value `router_id_as_loopback`: true. Allowed values `static_routes.preference`: 1-255. Default value `static_routes.preference`: 1. Default value `static_routes.bfd`: false. Allowed values `static_routes.next_hops.preference`: 1-255. Default value `static_routes.next_hops.preference`: 1. Choices `type`: `prefix`, `none`. Default value `type`: `prefix`. Allowed values `bgp_peers.remote_as`: 0-4294967295. Default value `bgp_peers.allow_self_as`: false. Default value `bgp_peers.as_override`: false. Default value `bgp_peers.disable_peer_as_check`: false. Default value `bgp_peers.next_hop_self`: false. Default value `bgp_peers.send_community`: false. Default value `bgp_peers.send_ext_community`: false. Allowed values `bgp_peers.allowed_self_as_count`: 1-10. Default value `bgp_peers.allowed_self_as_count`: 3. Default value `bgp_peers.bfd`: false. Default value `bgp_peers.disable_connected_check`: false. Allowed values `bgp_peers.ttl`: 1-255. Default value `bgp_peers.ttl`: 1. Allowed values `bgp_peers.weight`: 0-65535. Default value `bgp_peers.weight`: 0. Default value `bgp_peers.remove_all_private_as`: false. Default value `bgp_peers.remove_private_as`: false. Default value `bgp_peers.replace_private_as_with_local_as`: false. Default value `bgp_peers.unicast_address_family`: true. Default value `bgp_peers.multicast_address_family`: true. Default value `bgp_peers.admin_state`: true. Allowed values `bgp_peers.local_as`: 0-4294967295. Choices `bgp_peers.as_propagate`: `none`, `no-prepend`, `replace-as`, `dual-as`. Default value `bgp_peers.as_propagate`: `none`."
  type = list(object({
    node_id               = number
    pod_id                = optional(number, 1)
    router_id             = string
    router_id_as_loopback = optional(bool, true)
    loopback              = optional(string)
    static_routes = optional(list(object({
      prefix      = string
      description = optional(string, "")
      preference  = optional(number, 1)
      bfd         = optional(bool, false)
      next_hops = optional(list(object({
        ip         = string
        preference = optional(number, 1)
        type       = optional(string, "prefix")
      })), [])
    })), [])
    bgp_peers = optional(list(object({
      ip                               = string
      remote_as                        = string
      description                      = optional(string, "")
      allow_self_as                    = optional(bool, false)
      as_override                      = optional(bool, false)
      disable_peer_as_check            = optional(bool, false)
      next_hop_self                    = optional(bool, false)
      send_community                   = optional(bool, false)
      send_ext_community               = optional(bool, false)
      password                         = optional(string)
      allowed_self_as_count            = optional(number, 3)
      bfd                              = optional(bool, false)
      disable_connected_check          = optional(bool, false)
      ttl                              = optional(number, 1)
      weight                           = optional(number, 0)
      remove_all_private_as            = optional(bool, false)
      remove_private_as                = optional(bool, false)
      replace_private_as_with_local_as = optional(bool, false)
      unicast_address_family           = optional(bool, true)
      multicast_address_family         = optional(bool, true)
      admin_state                      = optional(bool, true)
      local_as                         = optional(number)
      as_propagate                     = optional(string, "none")
      peer_prefix_policy               = optional(string)
      export_route_control             = optional(string)
      import_route_control             = optional(string)
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for n in var.nodes : (n.node_id >= 1 && n.node_id <= 4000)
    ])
    error_message = "`node_id`: Minimum value: `1`. Maximum value: `4000`."
  }

  validation {
    condition = alltrue([
      for n in var.nodes : n.pod_id == null || try(n.pod_id >= 1 && n.pod_id <= 255, false)
    ])
    error_message = "`pod_id`: Minimum value: `1`. Maximum value: `255`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for s in coalesce(n.static_routes, []) : can(regex("^[a-zA-Z0-9\\!#$%()*,-./:;@ _{|}~?&+]{0,128}$", s.description))]
    ]))
    error_message = "`static_routes.description`: Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `\\`, `!`, `#`, `$`, `%`, `(`, `)`, `*`, `,`, `-`, `.`, `/`, `:`, `;`, `@`, ` `, `_`, `{`, `|`, }`, `~`, `?`, `&`, `+`. Maximum characters: 128."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for s in coalesce(n.static_routes, []) : s.preference == null || try(s.preference >= 1 && s.preference <= 255, false)]
    ]))
    error_message = "`static_routes.preference`: Minimum value: `1`. Maximum value: `255`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for s in coalesce(n.static_routes, []) : [for nh in coalesce(s.next_hops, []) : nh.preference == null || try(nh.preference >= 1 && nh.preference <= 255, false)]]
    ]))
    error_message = "`static_routes.next_hops.preference`: Minimum value: `1`. Maximum value: `255`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for s in coalesce(n.static_routes, []) : [for nh in coalesce(s.next_hops, []) : nh.type == null || try(contains(["prefix", "none"], nh.type), false)]]
    ]))
    error_message = "`static_routes.next_hops.type`: Allowed values are `prefix` or `none`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for b in coalesce(n.bgp_peers, []) : b.remote_as >= 0 && b.remote_as <= 4294967295]
    ]))
    error_message = "`bgp_peers.remote_as`: Minimum value: `0`. Maximum value: `4294967295`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for b in coalesce(n.bgp_peers, []) : b.description == null || try(can(regex("^[a-zA-Z0-9\\!#$%()*,-./:;@ _{|}~?&+]{0,128}$", b.description)), false)]
    ]))
    error_message = "`bgp_peers.description`: Allowed characters: `a`-`z`, `A`-`Z`, `0`-`9`, `\\`, `!`, `#`, `$`, `%`, `(`, `)`, `*`, `,`, `-`, `.`, `/`, `:`, `;`, `@`, ` `, `_`, `{`, `|`, }`, `~`, `?`, `&`, `+`. Maximum characters: 128."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for b in coalesce(n.bgp_peers, []) : try(b.allowed_self_as_count >= 1 && b.allowed_self_as_count <= 10, false)]
    ]))
    error_message = "`bgp_peers.allowed_self_as_count`: Minimum value: `1`. Maximum value: `10`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for b in coalesce(n.bgp_peers, []) : try(b.ttl >= 1 && b.ttl <= 255, false)]
    ]))
    error_message = "`bgp_peers.ttl`: Minimum value: `1`. Maximum value: `255`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for b in coalesce(n.bgp_peers, []) : try(b.weight >= 0 && b.weight <= 65535, false)]
    ]))
    error_message = "`bgp_peers.weight`: Minimum value: `0`. Maximum value: `65535`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for b in coalesce(n.bgp_peers, []) : b.local_as == null || try(b.local_as >= 0 && b.local_as <= 4294967295, false)]
    ]))
    error_message = "`bgp_peers.local_as`: Minimum value: `0`. Maximum value: `4294967295`."
  }

  validation {
    condition = alltrue(flatten([
      for n in var.nodes : [for b in coalesce(n.bgp_peers, []) : b.as_propagate == null || try(contains(["none", "no-prepend", "replace-as", "dual-as"], b.as_propagate), false)]
    ]))
    error_message = "`bgp_peers.as_propagate`: Allowed value are: `none`, `no-prepend`, `replace-as` or `dual-as`."
  }
}
