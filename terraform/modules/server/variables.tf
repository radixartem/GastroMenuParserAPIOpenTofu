variable "server_name"      { type = string }
variable "server_type"      { type = string }
variable "image"            { type = string }
variable "location"         { type = string }
variable "ssh_key_ids"      { type = list(number) }
variable "user_data"        { type = string; default = "" }
variable "firewall_ids"     { type = list(number); default = [] }
variable "volume_id"        { type = number; default = null }
variable "prevent_destroy"  { type = bool; default = true }
variable "environment"      { type = string; default = "production" }
variable "labels"           { type = map(string); default = {} }