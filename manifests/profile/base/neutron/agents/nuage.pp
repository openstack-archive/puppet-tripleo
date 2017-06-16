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
#   Defaults to hiera('keystone_public_api_virtual_ip')
#
# [*nova_metadata_ip*]
#   (Optional) Nova metadata node IPs
#   Defaults to hiera('nova_metadata_node_ips')
#
# [*nova_os_password*]
#   (Optional) Nova password
#   Defaults to hiera('nova_password')
#
# [*nova_os_tenant_name*]
#   (Optional) Nova tenant name
#   Defaults to hiera('nova_os_tenant_name')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::agents::nuage (
  $nova_auth_ip        = hiera('keystone_public_api_virtual_ip', ''),
  $nova_metadata_ip    = hiera('nova_metadata_node_ips', ''),
  $nova_os_password    = hiera('nova_password', ''),
  $nova_os_tenant_name = hiera('nova::api::admin_tenant_name', ''),
  $step                = Integer(hiera('step')),
) {
  if $step >= 4 {
    include ::nuage::vrs

    class { '::nuage::metadataagent':
      nova_os_tenant_name => $nova_os_tenant_name,
      nova_os_password    => $nova_os_password,
      nova_metadata_ip    => $nova_metadata_ip,
      nova_auth_ip        => $nova_auth_ip,
    }
  }
}
