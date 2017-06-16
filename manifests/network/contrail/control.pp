#
# Copyright (C) 2015 Juniper Networks
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
# == Class: tripleo::network::contrail::control
#
# Configure Contrail Control services
#
# == Parameters:
#
# [*admin_password*]
#  (optional) admin password
#  String value.
#  Defaults to hiera('contrail::admin_password'),
#
# [*admin_tenant_name*]
#  (optional) admin tenant name.
#  String value.
#  Defaults to hiera('contrail::admin_tenant_name'),
#
# [*admin_token*]
#  (optional) admin token
#  String value.
#  Defaults to hiera('contrail::admin_token'),
#
# [*admin_user*]
#  (optional) admin user name.
#  String value.
#  Defaults to hiera('contrail::admin_user'),
#
# [*api_server*]
#  (optional) IP address of api server
#  String value.
#  Defaults to hiera('contrail_config_vip',hiera('internal_api_virtual_ip'))
#
# [*api_port*]
#  (optional) port of api server
#  String value.
#  Defaults to hiera('contrail::api_port')
#
# [*auth_host*]
#  (optional) keystone server ip address
#  String (IPv4) value.
#  Defaults to hiera('contrail::auth_host'),
#
# [*auth_port*]
#  (optional) keystone port.
#  Defaults to hiera('contrail::auth_port'),
#
# [*auth_protocol*]
#  (optional) authentication protocol.
#  Defaults to hiera('contrail::auth_protocol'),
#
# [*disc_server_ip*]
#  (optional) IPv4 address of discovery server.
#  String (IPv4) value.
#  Defaults to hiera('contrail::disc_server_ip'),
#
# [*disc_server_port*]
#  (optional) port Discovery server listens on.
#  Integer value.
#  Defaults to hiera('contrail::disc_server_port'),
#
# [*host_ip*]
#  (optional) IP address of host
#  String (IPv4) value.
#  Defaults to hiera('contrail::control::host_ip')
#
# [*ibgp_auto_mesh*]
#  (optional) iBPG auto mesh
#  String value.
#  Defaults to true
#
# [*ifmap_password*]
#  (optional) ifmap password
#  String value.
#  Defaults to hiera('contrail::ifmap_password'),
#
# [*ifmap_username*]
#  (optional) ifmap username
#  String value.
#  Defaults to hiera('contrail::ifmap_username'),
#
# [*insecure*]
#  (optional) insecure mode.
#  Defaults to hiera('contrail::insecure'),
#
# [*memcached_servers*]
#  (optional) IPv4 address of memcached servers
#  String (IPv4) value + port
#  Defaults to hiera('contrail::memcached_servers'),
#
# [*manage_named*]
#  (optional) switch for managing named
#  String
#  Defaults to hiera('contrail::manage_named'),
#
# [*internal_vip*]
#  (optional) Public Virtual IP address
#  String (IPv4) value
#  Defaults to hiera('internal_api_virtual_ip')
#
# [*router_asn*]
#  (optional) Autonomus System Number
#  String value
#  Defaults to hiera('contrail::control::asn')
#
# [*secret*]
#  (optional) RNDC secret for named
#  String value
#  Defaults to hiera('contrail::control::rndc_secret')
#
# [*step*]
#  (optional) Step stack is in
#  Integer value.
#  Defaults to hiera('step')
#
class tripleo::network::contrail::control(
  $step              = Integer(hiera('step')),
  $admin_password    = hiera('contrail::admin_password'),
  $admin_tenant_name = hiera('contrail::admin_tenant_name'),
  $admin_token       = hiera('contrail::admin_token'),
  $admin_user        = hiera('contrail::admin_user'),
  $api_server        = hiera('contrail_config_vip',hiera('internal_api_virtual_ip')),
  $api_port          = hiera('contrail::api_port'),
  $auth_host         = hiera('contrail::auth_host'),
  $auth_port         = hiera('contrail::auth_port'),
  $auth_protocol     = hiera('contrail::auth_protocol'),
  $disc_server_ip    = hiera('contrail_config_vip',hiera('internal_api_virtual_ip')),
  $disc_server_port  = hiera('contrail::disc_server_port'),
  $host_ip           = hiera('contrail::control::host_ip'),
  $ibgp_auto_mesh    = true,
  $ifmap_password    = hiera('contrail::control::host_ip'),
  $ifmap_username    = hiera('contrail::control::host_ip'),
  $insecure          = hiera('contrail::insecure'),
  $memcached_servers = hiera('contrail::memcached_server'),
  $internal_vip        = hiera('internal_api_virtual_ip'),
  $router_asn        = hiera('contrail::control::asn'),
  $secret            = hiera('contrail::control::rndc_secret'),
  $manage_named      = hiera('contrail::control::manage_named'),
)
{
  $control_ifmap_user     = "${ifmap_username}.control"
  $control_ifmap_password = "${ifmap_username}.control"
  $dns_ifmap_user         = "${ifmap_username}.dns"
  $dns_ifmap_password     = "${ifmap_username}.dns"

  if $step >= 3 {
    class {'::contrail::control':
      secret                 => $secret,
      manage_named           => $manage_named,
      control_config         => {
        'DEFAULT'   => {
          'hostip' => $host_ip,
        },
        'DISCOVERY' => {
          'port'   => $disc_server_port,
          'server' => $disc_server_ip,
        },
        'IFMAP'     => {
          'password' => $control_ifmap_user,
          'user'     => $control_ifmap_password,
        },
      },
      dns_config             => {
        'DEFAULT'   => {
          'hostip'      => $host_ip,
          'rndc_secret' => $secret,
        },
        'DISCOVERY' => {
          'port'   => $disc_server_port,
          'server' => $disc_server_ip,
        },
        'IFMAP'     => {
          'password' => $dns_ifmap_user,
          'user'     => $dns_ifmap_password,
        }
      },
      control_nodemgr_config => {
        'DISCOVERY' => {
          'port'   => $disc_server_port,
          'server' => $disc_server_ip,
        },
      },
    }
  }
  if $step >= 5 {
    class {'::contrail::control::provision_control':
      api_address                => $api_server,
      api_port                   => $api_port,
      control_node_address       => $host_ip,
      control_node_name          => $::hostname,
      ibgp_auto_mesh             => $ibgp_auto_mesh,
      keystone_admin_user        => $admin_user,
      keystone_admin_password    => $admin_password,
      keystone_admin_tenant_name => $admin_tenant_name,
      router_asn                 => $router_asn,
    }
  }
}
