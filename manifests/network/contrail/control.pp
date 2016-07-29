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
#  (required) admin password
#  String value.
#
# [*admin_tenant_name*]
#  (required) admin tenant name.
#  String value.
#
# [*admin_token*]
#  (required) admin token
#  String value.
#
# [*admin_user*]
#  (required) admin user name.
#  String value.
#
# [*auth_host*]
#  (required) keystone server ip address
#  String (IPv4) value.
#
# [*disc_server_ip*]
#  (required) IPv4 address of discovery server.
#  String (IPv4) value.
#
# [*host_ip*]
#  (required) host IP address of Control
#  String (IPv4) value.
#
# [*ifmap_password*]
#  (required) ifmap password
#  String value.
#
# [*ifmap_server_ip*]
#  (required) ifmap server ip address.
#  String value.
#
# [*ifmap_username*]
#  (required) ifmap username
#  String value.
#
# [*auth_port*]
#  (required) keystone port.
#  Defaults to 35357.
#
# [*auth_protocol*]
#  (required) authentication protocol.
#  Defaults to http.
#
# [*disc_server_port*]
#  (required) port Discovery server listens on.
#  Integer value.
#  Defaults to 5998
#
# [*insecure*]
#  (required) insecure mode.
#  Defaults to false
#
# [*memcached_servers*]
#  (optional) IPv4 address of memcached servers
#  String (IPv4) value + port
#  Defaults to '127.0.0.1:12111'
#
# [*multi_tenancy*]
#  (required) Defines if mutli-tenancy is enabled.
#  Defaults to 'true'.
#
class tripleo::network::contrail::control(
  $admin_tenant_name = hiera('contrail::admin_tenant_name'),
  $admin_token = hiera('contrail::admin_token'),
  $admin_password = hiera('contrail::admin_password'),
  $admin_user = hiera('contrail::admin_user'),
  $auth_host = hiera('contrail::auth_host'),
  $disc_server_ip = hiera('contrail::disc_server_ip'),
  $host_ip,
  $ifmap_password,
  $ifmap_username,
  $auth_port = hiera('contrail::auth_port'),
  $auth_protocol = hiera('contrail::auth_protocol'),
  $disc_server_port = hiera('contrail::disc_server_port'),
  $insecure = hiera('contrail::insecure'),
  $memcached_servers = hiera('contrail::memcached_server'),
)
{
  class {'::contrail::keystone':
    keystone_config => {
      'KEYSTONE' => {
        'admin_tenant_name' => $admin_tenant_name,
        'admin_token'       => $admin_token,
        'admin_password'    => $admin_password,
        'admin_user'        => $admin_user,
        'auth_host'         => $auth_host,
        'auth_port'         => $auth_port,
        'auth_protocol'     => $auth_protocol,
        'insecure'          => $insecure,
        'memcached_servers' => $memcached_servers,
      },
    },
  } ->
  class {'::contrail::control':
    control_config         => {
      'DEFAULTS'  => {
        'hostip' => $host_ip,
      },
      'DISCOVERY' => {
        'port'   => $disc_server_port,
        'server' => $disc_server_ip,
      },
      'IFMAP'     => {
        'password' => $ifmap_password,
        'user'     => $ifmap_username,
      },
    },
    dns_config             => {
      'DEFAULTS'  => {
        'hostip' => $host_ip,
      },
      'DISCOVERY' => {
        'port'   => $disc_server_port,
        'server' => $disc_server_ip,
      },
      'IFMAP'     => {
        'password' => $ifmap_password,
        'user'     => $ifmap_username,
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
