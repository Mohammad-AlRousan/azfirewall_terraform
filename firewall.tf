locals {
  # Determine resource group name and location
  resource_group_name = coalesce(
    data.azurerm_resource_group.rgrp[*].name,
    azurerm_resource_group.rg[*].name,
    [""]
  )[0]
  location            = coalesce(
    data.azurerm_resource_group.rgrp[*].location,
    azurerm_resource_group.rg[*].location,
    [""]
  )[0]
  
  # Convert public IP names to a map for easy lookup
  public_ip_map       = { for pip in var.public_ip_names : pip => true }

  # Convert firewall rules to maps for easy lookup
  fw_nat_rules        = { for idx, rule in var.firewall_nat_rules : rule.name => { idx : idx, rule : rule } }
  fw_network_rules    = { for idx, rule in var.firewall_network_rules : rule.name => { idx : idx, rule : rule } }
  fw_application_rules = { for idx, rule in var.firewall_application_rules : rule.name => { idx : idx, rule : rule } }
}

# Resource Group Creation or selection
resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = lower(local.resource_group_name)
  location = local.location
  tags     = merge({ "ResourceName" = format("%s", local.resource_group_name) }, var.tags)
}

# Firewall Subnet Creation or selection
resource "azurerm_subnet" "fw-snet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.firewall_subnet_address_prefix
  service_endpoints    = var.firewall_service_endpoints
}

# Firewall Management Subnet Creation
resource "azurerm_subnet" "fw-mgnt-snet" {
  count                = var.enable_forced_tunneling ? 1 : 0
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.firewall_management_subnet_address_prefix
}

# Public IP resources for Azure Firewall
resource "azurerm_public_ip_prefix" "fw-pref" {
  name                = lower("${var.firewall_config.name}-pip-prefix")
  resource_group_name = local.resource_group_name
  location            = local.location
  prefix_length       = var.public_ip_prefix_length
  tags                = merge({ "ResourceName" = lower("${var.firewall_config.name}-pip-prefix") }, var.tags)
}

resource "azurerm_public_ip" "fw-pip" {
  for_each            = local.public_ip_map
  name                = lower("pip-${var.firewall_config.name}-${each.key}")
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.fw-pref.id
  tags                = merge({ "ResourceName" = lower("pip-${var.firewall_config.name}-${each.key}") }, var.tags)
}

resource "azurerm_public_ip" "fw-mgnt-pip" {
  count               = var.enable_forced_tunneling ? 1 : 0
  name                = lower("pip-${var.firewall_config.name}-fw-mgnt")
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge({ "ResourceName" = lower("pip-${var.firewall_config.name}-fw-mgnt") }, var.tags)
}

# Azure Firewall 
resource "azurerm_firewall" "fw" {
  name                = format("%s", var.firewall_config.name)
  resource_group_name = local.resource_group_name
  location            = local.location
  sku_name            = var.firewall_config.sku_name
  sku_tier            = var.firewall_config.sku_tier
  dns_servers         = var.firewall_config.dns_servers
  private_ip_ranges   = var.firewall_config.private_ip_ranges
  threat_intel_mode   = lookup(var.firewall_config, "threat_intel_mode", "Alert")
  zones               = var.firewall_config.zones
  tags                = merge({ "ResourceName" = format("%s", var.firewall_config.name) }, var.tags)

  dynamic "ip_configuration" {
    for_each = local.public_ip_map
    content {
      name                 = ip.key
      subnet_id            = ip.key == var.public_ip_names[0] ? azurerm_subnet.fw-snet.id : null
      public_ip_address_id = azurerm_public_ip.fw-pip[ip.key].id
    }
  }

  dynamic "management_ip_configuration" {
    for_each = var.enable_forced_tunneling ? [1] : []
    content {
      name                 = lower("${var.firewall_config.name}-forced-tunnel")
      subnet_id            = azurerm_subnet.fw-mgnt-snet[0].id
      public_ip_address_id = azurerm_public_ip.fw-mgnt-pip[0].id
    }
  }
}

# Azure Firewall Network/Application/NAT Rules 
resource "azurerm_firewall_application_rule_collection" "fw_app" {
  for_each            = local.fw_application_rules
  name                = lower(format("fw-app-rule-%s-${var.firewall_config.name}-${local.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = local.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name             = each.key
    description      = each.value.rule.description
    source_addresses = each.value.rule.source_addresses
    source_ip_groups = each.value.rule.source_ip_groups
    fqdn_tags        = each.value.rule.fqdn_tags
    target_fqdns     = each.value.rule.target_fqdns
    protocol {
      type = each.value.rule.protocol.type
      port = each.value.rule.protocol.port
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "fw" {
  for_each            = local.fw_network_rules
  name                = lower(format("fw-net-rule-%s-${var.firewall_config.name}-${local.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = local.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name                  = each.key
    description           = each.value.rule.description
    source_addresses      = each.value.rule.source_addresses
    destination_ports     = each.value.rule.destination_ports
    destination_addresses = [for dest in
    each.value.rule.destination_addresses : contains(var.public_ip_names, dest) ? azurerm_public_ip.fw-pip[dest].ip_address : dest]
    destination_fqdns     = each.value.rule.destination_fqdns
    protocols             = each.value.rule.protocols
  }
}

resource "azurerm_firewall_nat_rule_collection" "fw" {
  for_each            = local.fw_nat_rules
  name                = lower(format("fw-nat-rule-%s-${var.firewall_config.name}-${local.location}", each.key))
  azure_firewall_name = azurerm_firewall.fw.name
  resource_group_name = local.resource_group_name
  priority            = 100 * (each.value.idx + 1)
  action              = each.value.rule.action

  rule {
    name                  = each.key
    description           = each.value.rule.description
    source_addresses      = each.value.rule.source_addresses
    destination_ports     = each.value.rule.destination_ports
    destination_addresses = [for dest in each.value.rule.destination_addresses : contains(var.public_ip_names, dest) ? azurerm_public_ip.fw-pip[dest].ip_address : dest]
    protocols             = each.value.rule.protocols
    translated_address    = each.value.rule.translated_address
    translated_port       = each.value.rule.translated_port
  }
}

# Azure Firewall and Public IP's monitoring diagnostics
resource "azurerm_monitor_diagnostic_setting" "fw-diag" {
  count                      = var.log_analytics_workspace_id != null || var.storage_account_name != null ? 1 : 0
  name                       = lower("${var.firewall_config.name}-diag")
  target_resource_id         = azurerm_firewall.fw.id
  storage_account_id         = var.storage_account_name != null ? data.azurerm_storage_account.storeacc[0].id : null
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = var.fw_diag_logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
      days    = 0
    }
  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}
