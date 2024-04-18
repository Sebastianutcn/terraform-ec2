output stringvar {
  value       = var.stringvar
}

output numbervar {
  value       = var.numbervar
}

output booleanvar {
  value       = var.booleanvar
}

# output listvar {
#   value       = var.listvar
# }

output listvar {
  value       = var.listvar[1]
}

# output mapvar {
#   value       = var.mapvar
# }

# output objectvar {
#   value       = var.objectvar
# } 

output mapobjectvar {
  value       = var.mapobjectvar
} 

output locala {
  value       = local.a
}
