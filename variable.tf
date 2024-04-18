variable stringvar {
  type        = string
}

variable numbervar {
  type        = number
  default     = 1
}

variable listvar {
  type        = list(string)
}

# variable objectvar {
#   type        = object ({
#     cidr_block = string
#     region = string
#   })
# }

variable mapobjectvar {
  type        = map(object ({
    cidr_block = string
    region = string
  }))
}


