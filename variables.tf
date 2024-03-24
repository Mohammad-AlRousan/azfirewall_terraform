variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group to use or create."
  type        = string
  default     = "my_resource_group"
}

variable "location" {
  description = "Azure region where the resources will be deployed."
  type        = string
  default     = "East US"
}

variable "virtual_network_name" {
  description = "Name of the virtual network where the firewall will be deployed."
  type        = string
}

variable "public_ip_names" {
  description = "List of public IP names to associate with the firewall."
  type        = list(string)
  default     = []
}

variable "firewall_subnet_address_prefix" {
  description = "Address prefix for the firewall subnet."
  type        = string
  default     = "10.0.2.0/24"  # Example address prefix, replace with your desired value
}

variable "firewall_service_endpoints" {
  description = "List of service endpoints for the firewall subnet."
  type        = list(string)
  default     = []  # Example list of service endpoints, replace with your desired values
}

variable "enable_forced_tunneling" {
  description = "Whether forced tunneling is enabled for the firewall."
  type        = bool
  default     = false
}

variable "firewall_management_subnet_address_prefix" {
  description = "Address prefix for the firewall management subnet."
  type        = string
  default     = "10.0.3.0/24"  # Example address prefix, replace with your desired value
}

# Variables for firewall configuration
variable "firewall_config" {
  description = "Configuration settings for the Azure Firewall."
  type        = object({
    name              = string
    sku_name          = string
    sku_tier          = string
    dns_servers       = list(string)
    private_ip_ranges = list(string)
    threat_intel_mode = string
    zones             = list(string)
  })
  default = {
    name              = "my_firewall"
    sku_name          = "AZFW_VNet"
    sku_tier          = "Standard"
    dns_servers       = []
    private_ip_ranges = []
    threat_intel_mode = "Alert"
    zones             = ["1", "2", "3"]
  }
}

# Variables for firewall rules
variable "firewall_nat_rules" {
  description = "List of NAT rules for the Azure Firewall."
  type        = list(object({
    name               = string
    idx                = number
    action             = string
    description        = string
    source_addresses   = list(string)
    destination_ports  = list(string)
    destination_addresses = list(string)
    protocols          = list(string)
    translated_address = string
    translated_port    = string
  }))
  default = []
}

variable "firewall_network_rules" {
  description = "List of network rules for the Azure Firewall."
  type        = list(object({
    name                    = string
    idx                     = number
    action                  = string
    description             = string
    source_addresses        = list(string)
    destination_ports       = list(string)
    destination_addresses   = list(string)
    destination_fqdns       = list(string)
    protocols               = list(string)
  }))
  default = []
}

variable "firewall_application_rules" {
  description = "List of application rules for the Azure Firewall."
  type        = list(object({
    name                  = string
    idx                   = number
    action                = string
    description           = string
    source_addresses      = list(string)
    source_ip_groups      = list(string)
    fqdn_tags             = list(string)
    target_fqdns          = list(string)
    protocol              = object({
      type = string
      port = string
    })
  }))
  default = []
}

# Variables for logging and diagnostics
variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostics."
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Name of the storage account for diagnostics."
  type        = string
  default     = ""
}

variable "fw_diag_logs" {
  description = "List of diagnostic logs for the firewall."
  type        = list(string)
  default     = []
}

variable "fw_pip_diag_logs" {
  description = "List of diagnostic logs for public IPs associated with the firewall."
  type        = list(string)
  default     = []
}
# Variables for firewall policy (if applicable)
variable "firewall_policy" {
  description = "Configuration settings for the Azure Firewall Policy."
  type        = object({
    sku                     = string
    base_policy_id          = string
    threat_intelligence_mode = string
    dns                     = object({
      servers       = list(string)
      proxy_enabled = bool
    })
    threat_intelligence_allowlist = object({
      ip_addresses = list(string)
      fqdns        = list(string)
    })
  })
  default = null
}

# Variables for virtual hub
variable "virtual_hub" {
  description = "Configuration settings for the virtual hub."
  type        = object({
    virtual_hub_id    = string
    public_ip_count   = number
  })
  default = null
}

# Tags variable
variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}


