# Without default values.

variable "StorageAccountName" {
  type        = string
  description = "The name of the storage account to use"
}

variable "FtpFileContainerName" {
  type        = string
  description = "The name of the container to use in the storage account."
}

variable "vmSize" {
  type        = string
  description = "The size of Azure VM."
}

variable "username" {
  type        = string
  description = "Username for the Virtual Machine."
}

variable "dnsLabelPrefix" {
  type        = string
  description = "Unique DNS Name for the Public IP used to access the Virtual Machine."
}

variable "location" {
  type        = string
  description = "Location for all resources."
}

# With default values.

variable "scenarioPrefix" {
  type    = string
  default = "blobstorageftp"
}

variable "imagePublisher" {
  type    = string
  default = "Canonical"
}

variable "imageOffer" {
  type    = string
  default = "UbuntuServer"
}

variable "ubuntuOSVersion" {
  type    = string
  default = "18.04-LTS"
}

variable "vnetAddressPrefix" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnetPrefix" {
  type    = string
  default = "10.0.0.0/24"
}

variable "publicIPAddressType" {
  type    = string
  default = "Dynamic"
}

variable "vmStorageAccountContainerName" {
  type    = string
  default = "ftpfiles"
}
