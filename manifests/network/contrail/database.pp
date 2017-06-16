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
# == Class: tripleo::network::contrail::database
#
# Configure Contrail Database services
#
# == Parameters:
#
# [*admin_password*]
#  (optional) admin password
#  String value.
#  Defaults to hiera('contrail::admin_password')
#
# [*admin_tenant_name*]
#  (optional) admin tenant name.
#  String value.
#  Defaults to hiera('contrail::admin_tenant_name')
#
# [*admin_token*]
#  (optional) admin token
#  String value.
#  Defaults to hiera('contrail::admin_token')
#
# [*admin_user*]
#  (optional) admin user name.
#  String value.
#  Defaults to hiera('contrail::admin_user')
#
# [*api_server*]
#  (optional) VIP of Config API
#  String (IPv4) value.
#  Defaults to hiera('contrail_config_vip',hiera('internal_api_virtual_ip'))
#
# [*api_port*]
#  (optional) Port of Config API
#  String value.
#  Defaults to hiera('contrail::api_port')
#
# [*auth_host*]
#  (optional) keystone server ip address
#  String (IPv4) value.
#  Defaults to hiera('contrail::auth_host')
#
# [*cassandra_servers*]
#  (optional) List IPs+port of Cassandra servers
#  Array of strings value.
#  Defaults to hiera('contrail_database_node_ips')
#
# [*disc_server_ip*]
#  (optional) IPv4 address of discovery server.
#  String (IPv4) value.
#  Defaults to hiera('contrail::disc_server_ip')
#
# [*disc_server_port*]
#  (optional) port Discovery server listens on.
#  Integer value.
#  Defaults to hiera('contrail::disc_server_port')
#
# [*host_ip*]
#  (required) host IP address of Database node
#  String (IPv4) value.
#
# [*host_name*]
#  (optional) host name of Database node
#  String value.
#  Defaults to $::hostname
#
# [*internal_vip*]
#  (optional) Public virtual ip
#  String value.
#  Defaults to hiera('internal_api_virtual_ip')
#
# [*step*]
#  (optional) Step stack is in
#  Integer value.
#  Defaults to hiera('step')
#
# [*zookeeper_client_ip*]
#  (optional) Zookeeper listen address
#  String (IPv4) value.
#  Defaults to hiera('contrail::database::host_ip')
#
# [*zookeeper_hostnames*]
#  (optional) Zookeeper hostname list
#  Array of string value.
#  Defaults to hiera('contrail_database_short_node_names')
#
# [*zookeeper_server_ips*]
#  (optional) Zookeeper ip list
#  Array of string (IPv4) values
#  Defaults to hiera('contrail_database_node_ips')
#
class tripleo::network::contrail::database(
  $admin_password       = hiera('contrail::admin_password'),
  $admin_tenant_name    = hiera('contrail::admin_tenant_name'),
  $admin_token          = hiera('contrail::admin_token'),
  $admin_user           = hiera('contrail::admin_user'),
  $api_server           = hiera('contrail_config_vip',hiera('internal_api_virtual_ip')),
  $api_port             = hiera('contrail::api_port'),
  $auth_host            = hiera('contrail::auth_host'),
  $cassandra_servers    = hiera('contrail_database_node_ips'),
  $disc_server_ip       = hiera('contrail_config_vip',hiera('internal_api_virtual_ip')),
  $disc_server_port     = hiera('contrail::disc_server_port'),
  $host_ip              = hiera('contrail::database::host_ip'),
  $host_name            = $::hostname,
  $internal_vip         = hiera('internal_api_virtual_ip'),
  $step                 = Integer(hiera('step')),
  $zookeeper_client_ip  = hiera('contrail::database::host_ip'),
  $zookeeper_hostnames  = hiera('contrail_database_short_node_names'),
  $zookeeper_server_ips = hiera('contrail_database_node_ips'),
)
{
  if $step == 2 {
    class {'::contrail::database':
      database_params => {
        'auth_host'             => $auth_host,
        'api_server'            => $api_server,
        'admin_password'        => $admin_password,
        'admin_tenant_name'     => $admin_tenant_name,
        'admin_token'           => $admin_token,
        'admin_user'            => $admin_user,
        'cassandra_servers'     => $cassandra_servers,
        'host_ip'               => $host_ip,
        'disc_server_ip'        => $disc_server_ip,
        'disc_server_port'      => $disc_server_port,
        'zookeeper_client_ip'   => $zookeeper_client_ip,
        'zookeeper_hostnames'   => $zookeeper_hostnames,
        'zookeeper_server_ips'  => $zookeeper_server_ips,
        database_nodemgr_config => {
          'DEFAULT'   => {
            'hostip' => $host_ip,
          },
          'DISCOVERY' => {
            'port'   => $disc_server_port,
            'server' => $disc_server_ip,
          },
        },
      }
    }
  }
  if $step >= 5 {
    class {'::contrail::database::provision_database':
      api_address                => $api_server,
      api_port                   => $api_port,
      database_node_address      => $host_ip,
      database_node_name         => $host_name,
      keystone_admin_user        => $admin_user,
      keystone_admin_password    => $admin_password,
      keystone_admin_tenant_name => $admin_tenant_name,
      openstack_vip              => $auth_host,
    }
  }
}
