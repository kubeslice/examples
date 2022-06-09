variable "region" {
  type    = string
  default = "sa-east-1"
}

variable "key_pair" {
  type    = string
  default = "kubeslice-ec2"
}

variable "key_pair_file" {
  type    = string
  default = "/Users/juanveras/Documents/avesha/github/examples/ec2/ssh_key/kubeslice-ec2.pem"
}