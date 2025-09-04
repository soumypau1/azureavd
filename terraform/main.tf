# Azure Virtual Desktop Terraform Configuration
# Generated for: user@company.com
# AVD Size: small
# Hostpool: default-hostpool

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "avd_rg" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    Environment = "Production"
    Owner       = "user@company.com"
    Purpose     = "Azure Virtual Desktop"
    Size        = "small"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "avd_vnet" {
  name                = "avd-small-202509040832-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  
  tags = azurerm_resource_group.avd_rg.tags
}

# Subnet
resource "azurerm_subnet" "avd_subnet" {
  name                 = "avd-small-202509040832-subnet"
  resource_group_name  = azurerm_resource_group.avd_rg.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Host Pool
resource "azurerm_virtual_desktop_host_pool" "avd_hostpool" {
  name                = "default-hostpool"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  
  type               = "Pooled"
  load_balancer_type = "BreadthFirst"
  maximum_sessions_allowed = var.max_sessions
  
  tags = azurerm_resource_group.avd_rg.tags
}

# Application Group
resource "azurerm_virtual_desktop_application_group" "avd_dag" {
  name                = "avd-small-202509040832-dag"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  
  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.avd_hostpool.id
  friendly_name = "Desktop Application Group"
  description   = "Desktop Application Group for small AVD deployment"
  
  tags = azurerm_resource_group.avd_rg.tags
}

# Workspace
resource "azurerm_virtual_desktop_workspace" "avd_workspace" {
  name                = "avd-small-202509040832-workspace"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  
  friendly_name = "AVD Workspace"
  description   = "Azure Virtual Desktop Workspace for user@company.com"
  
  tags = azurerm_resource_group.avd_rg.tags
}

# Associate Application Group with Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd_workspace_dag" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.avd_dag.id
}

# Session Hosts
resource "azurerm_windows_virtual_machine" "avd_vm" {
  count               = var.session_host_count
  name                = "avd-small-202509040832-vm-${count.index + 1}"
  resource_group_name = azurerm_resource_group.avd_rg.name
  location            = azurerm_resource_group.avd_rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  
  disable_password_authentication = false
  
  network_interface_ids = [
    azurerm_network_interface.avd_nic[count.index].id,
  ]
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-avd"
    version   = "latest"
  }
  
  tags = azurerm_resource_group.avd_rg.tags
}

# Network Interfaces
resource "azurerm_network_interface" "avd_nic" {
  count               = var.session_host_count
  name                = "avd-small-202509040832-nic-${count.index + 1}"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = azurerm_resource_group.avd_rg.tags
}
