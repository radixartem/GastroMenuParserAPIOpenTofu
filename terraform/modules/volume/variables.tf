variable "volume_name"       { type = string }
variable "size"              { type = number }
variable "location"          { type = string }
variable "delete_protection" { type = bool; default = true }
variable "labels"            { type = map(string); default = {} }