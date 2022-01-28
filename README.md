<!-- BEGIN_TF_DOCS -->
[![Tests](https://github.com/netascode/terraform-aci-l3out-node-profile/actions/workflows/test.yml/badge.svg)](https://github.com/netascode/terraform-aci-l3out-node-profile/actions/workflows/test.yml)

# Terraform ACI L3out Node Profile Module

Description

Location in GUI:
`Tenants` » `XXX` » `Networking` » `L3outs` » `XXX` » `Logical Node Profiles`

## Examples

```hcl
module "aci_l3out_node_profile" {
  source  = "netascode/l3out-node-profile/aci"
  version = ">= 0.1.0"

  tenant = "ABC"
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aci"></a> [aci](#requirement\_aci) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | >= 2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_tenant"></a> [tenant](#input\_tenant) | Tenant name. | `string` | n/a | yes |
| <a name="input_l3out"></a> [l3out](#input\_l3out) | L3out name. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Node profile name. | `string` | n/a | yes |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | List of nodes. Allowed values `node_id`: 1-4000. Allowed values `pod_id`: 1-255. Default value `pod_id`: 1. Default value `router_id_as_loopback`: true. Allowed values `static_routes.preference`: 1-255. Default value `static_routes.preference`: 1. Allowed values `static_routes.next_hops.preference`: 1-255. Default value `static_routes.next_hops.preference`: 1. Choices `type`: `prefix`, `none`. Default value `type`: `prefix`. | <pre>list(object({<br>    node_id               = number<br>    pod_id                = optional(number)<br>    router_id             = string<br>    router_id_as_loopback = optional(bool)<br>    static_routes = optional(list(object({<br>      prefix      = string<br>      description = optional(string)<br>      preference  = optional(string)<br>      next_hops = optional(list(object({<br>        ip         = string<br>        preference = optional(number)<br>        type       = optional(string)<br>      })))<br>    })))<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dn"></a> [dn](#output\_dn) | Distinguished name of `l3extLNodeP` object. |
| <a name="output_name"></a> [name](#output\_name) | Node profile name. |

## Resources

| Name | Type |
|------|------|
| [aci_rest_managed.ipNexthopP](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.ipRouteP](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3extInfraNodeP](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3extLNodeP](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3extRsNodeL3OutAtt](https://registry.terraform.io/providers/CiscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
<!-- END_TF_DOCS -->