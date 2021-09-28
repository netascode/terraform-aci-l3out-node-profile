output "dn" {
  value       = aci_rest.l3extLNodeP.id
  description = "Distinguished name of `l3extLNodeP` object."
}

output "name" {
  value       = aci_rest.l3extLNodeP.content.name
  description = "Node profile name."
}
