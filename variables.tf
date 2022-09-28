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
  description = "List of nodes. Allowed values `node_id`: 1-4000. Allowed values `pod_id`: 1-255. Default value `pod_id`: 1. Default value `router_id_as_loopback`: true. Allowed values `static_routes.preference`: 1-255. Default value `static_routes.preference`: 1. Allowed values `static_routes.next_hops.preference`: 1-255. Default value `static_routes.next_hops.preference`: 1. Choices `type`: `prefix`, `none`. Default value `type`: `prefix`."
  type = list(object({
    node_id               = number
    pod_id                = optional(number, 1)
    router_id             = string
    router_id_as_loopback = optional(bool, true)
    static_routes = optional(list(object({
      prefix      = string
      description = optional(string, "")
      preference  = optional(number, 1)
      next_hops = optional(list(object({
        ip         = string
        preference = optional(number, 1)
        type       = optional(string, "prefix")
      })), [])
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
}
