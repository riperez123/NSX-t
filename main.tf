terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

provider "nsxt" {
  host                  = var.nsx_manager
  username              = var.nsx_username
  password              = var.nsx_password
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = "TNT48-OVERLAY-TZ"
}

data "nsxt_logical_tier0_router" "tier0_router" {
  display_name = "TNT48-T0"
}

data "nsxt_edge_cluster" "edge_cluster" {
  display_name = "TNT48-CLSTR"
}

data "nsxt_policy_tier1_gateway" "tier1_router" {
  display_name = "TNT48-T1"
}

data "nsxt_policy_service" "icmp" {
  display_name = "ICMPv4"
}

resource "nsxt_policy_segment" "segment1" {
  display_name        = "Terraform_segment_1(do not use for TF testing only)"
  description         = "Terraform provisioned Segment by Ricky"
  connectivity_path   = data.nsxt_policy_tier1_gateway.tier1_router.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    cidr = "10.10.10.1/24"
    # dhcp_ranges = ["10.10.10.100-10.10.10.160"]
  }
}

resource "nsxt_policy_group" "group1" {
  display_name = "RickysVM"
  description  = "TF provisioned group"

  criteria {
    condition {
      key         = "Name"
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      value       = "Ricky"
    }
  }
}

resource "nsxt_policy_security_policy" "policy1" {
  display_name = "RickyTF"
  description  = "Terraform provisioned Security Policy"
  category     = "Application"
  locked       = false
  stateful     = true
  tcp_strict   = false
  scope        = [nsxt_policy_group.group1.path]

  rule {
    display_name       = "block_icmp"
    destination_groups = [nsxt_policy_group.group1.path]
    action             = "REJECT"
    services           = ["/infra/services/ICMPv4-ALL"]
    logged             = true
  }
}

data "nsxt_policy_tier0_gateway" "T0" {
  display_name = "TNT48-T0"
}

data "nsxt_policy_edge_cluster" "EC" {
  display_name = "TNT48-CLSTR"
}

resource "nsxt_policy_tier1_gateway" "tier1_gw" {
  description               = "Ricky-Tier-1 provisioned by Terraform"
  display_name              = "Ricky-Tier1-gw1"
  nsx_id                    = "predefined_id"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.EC.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.T0.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"

  tag {
    scope = "testing"
    tag   = "Ricky"
  }
}

# data "nsxt_policy_tier1_gateway" "tier1_router_a" {
#   display_name = "Ricky-Tier1-gw1"
# }

# resource "nsxt_policy_segment" "segment2" {
#   display_name        = "Terraform_segment_1(do not use for TF testing only)"
#   description         = "Terraform provisioned Segment by Ricky"
#   connectivity_path   = data.nsxt_policy_tier1_gateway.tier1_router_a.path
#   transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

#   subnet {
#     cidr = "10.10.20.1/24"
#     # dhcp_ranges = ["10.10.20.100-10.10.20.160"]
#   }
# }


