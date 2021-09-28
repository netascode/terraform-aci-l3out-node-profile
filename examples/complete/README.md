<!-- BEGIN_TF_DOCS -->
# L3out Node Profile Example

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example will create resources. Resources can be destroyed with `terraform destroy`.

```hcl
module "aci_l3out_node_profile" {
  source  = "netascode/l3out-node-profile/aci"
  version = ">= 0.0.1"

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
<!-- END_TF_DOCS -->