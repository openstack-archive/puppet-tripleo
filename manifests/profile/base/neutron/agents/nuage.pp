# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::neutron::agents::nuage
#
# Nuage Neutron agent profile
#
# === Parameters
#
# [*nova_auth_ip*]
#   (Optional) Nova auth IP
#   Defaults to lookup('keystone_public_api_virtual_ip')
#
# [*nova_metadata_ip*]
#   (Optional) Nova metadata node IPs
#   Defaults to lookup('nova_metadata_node_ips')
#
# [*nova_os_password*]
#   (Optional) Nova password
#   Defaults to lookup('nova_password')
#
# [*nova_os_tenant_name*]
#   (Optional) Nova tenant name
#   Defaults to lookup('nova_os_tenant_name')
#
# [*enable_metadata_agent*]
#   (Optional) Enable metadata agent
#   Defaults to true
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::neutron::agents::nuage (
  $nova_auth_ip            = lookup('keystone_public_api_virtual_ip', undef, undef, ''),
  $nova_metadata_ip        = lookup('nova_metadata_node_ips', undef, undef, ''),
  $nova_os_password        = lookup('nova_password', undef, undef, ''),
  $nova_os_tenant_name     = lookup('nova::api::admin_tenant_name', undef, undef, ''),
  $enable_metadata_agent   = true,
  $step                    = Integer(lookup('step')),
) {
  if $step >= 4 {
    include nuage::vrs

    if $enable_metadata_agent {
      class { 'nuage::metadataagent':
        nova_os_tenant_name => $nova_os_tenant_name,
        nova_os_password    => $nova_os_password,
        nova_metadata_ip    => $nova_metadata_ip,
        nova_auth_ip        => $nova_auth_ip,
      }
    }
  }
}
