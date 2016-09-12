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
# == Class: tripleo::network::contrail::config
#
# Configure Contrail Config services
#
# == Parameters:
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
# [*rabbit_server*]
#  (required) IPv4 address of rabbit server.
#  String (IPv4) value.
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
# [*auth*]
#  (optional) Authentication method.
#  Defaults to hiera('contrail::auth')
#
# [*auth_host*]
#  (optional) keystone server ip address
#  String (IPv4) value.
#  Defaults to hiera('contrail::auth_host')
#
# [*auth_port*]
#  (optional) keystone port.
#  Defaults to hiera('contrail::auth_port')
#
# [*auth_protocol*]
#  (optional) authentication protocol.
#  Defaults to hiera('contrail::auth_protocol')
#
# [*cassandra_server_list*]
#  (optional) List IPs+port of Cassandra servers
#  Array of strings value.
#  Defaults to hiera('contrail::cassandra_server_list')
#
# [*disc_server_ip*]
#  (optional) IPv4 address of discovery server.
#  String (IPv4) value.
#  Defaults to hiera('contrail::disc_server_ip')
#
# [*insecure*]
#  (optional) insecure mode.
#  Defaults to hiera('contrail::insecure')
#
# [*listen_ip_address*]
#  (optional) IP address to listen on.
#  String (IPv4) value.
#  Defaults to '0.0.0.0'
#
# [*listen_port*]
#  (optional) Listen port for config-api
#  Defaults to 8082
#
# [*memcached_servers*]
#  (optional) IPv4 address of memcached servers
#  String (IPv4) value + port
#  Defaults to hiera('contrail::memcached_server')
#
# [*multi_tenancy*]
#  (optional) Defines if mutli-tenancy is enabled.
#  Defaults to hiera('contrail::multi_tenancy')
#
# [*redis_server*]
#  (optional) IPv4 address of redis server.
#  String (IPv4) value.
#  Defaults to '127.0.0.1'
#
# [*zk_server_ip*]
#  (optional) List IPs+port of Zookeeper servers
#  Array of strings value.
#  Defaults to hiera('contrail::zk_server_ip')
#
class tripleo::network::contrail::config(
  $ifmap_password,
  $ifmap_server_ip,
  $ifmap_username,
  $rabbit_server,
  $admin_password = hiera('contrail::admin_password'),
  $admin_tenant_name = hiera('contrail::admin_tenant_name'),
  $admin_token = hiera('contrail::admin_token'),
  $admin_user = hiera('contrail::admin_user'),
  $auth = hiera('contrail::auth'),
  $auth_host = hiera('contrail::auth_host'),
  $auth_port = hiera('contrail::auth_port'),
  $auth_protocol = hiera('contrail::auth_protocol'),
  $cassandra_server_list = hiera('contrail::cassandra_server_list'),
  $disc_server_ip = hiera('contrail::disc_server_ip'),
  $insecure = hiera('contrail::insecure'),
  $listen_ip_address = '0.0.0.0',
  $listen_port = 8082,
  $memcached_servers = hiera('contrail::memcached_server'),
  $multi_tenancy = hiera('contrail::multi_tenancy'),
  $redis_server = '127.0.0.1',
  $zk_server_ip = hiera('contrail::zk_server_ip'),
)
{
  validate_ip_address($listen_ip_address)
  validate_ip_address($disc_server_ip)
  validate_ip_address($ifmap_server_ip)
  class {'::contrail::keystone':
    keystone_config => {
      'KEYSTONE' => {
        'admin_password'    => $admin_password,
        'admin_tenant_name' => $admin_tenant_name,
        'admin_token'       => $admin_token,
        'admin_user'        => $admin_user,
        'auth_host'         => $auth_host,
        'auth_port'         => $auth_port,
        'auth_protocol'     => $auth_protocol,
        'insecure'          => $insecure,
        'memcached_servers' => $memcached_servers,
      },
    },
  } ->
  class {'::contrail::config':
    api_config            => {
      'DEFAULTS' => {
        'auth'                  => $auth,
        'cassandra_server_list' => $cassandra_server_list,
        'disc_server_ip'        => $disc_server_ip,
        'ifmap_password'        => $ifmap_password,
        'ifmap_server_ip'       => $ifmap_server_ip,
        'ifmap_username'        => $ifmap_username,
        'listen_ip_addr'        => $listen_ip_address,
        'listen_port'           => $listen_port,
        'multi_tenancy'         => $multi_tenancy,
        'rabbit_server'         => $rabbit_server,
        'redis_server'          => $redis_server,
        'zk_server_ip'          => $zk_server_ip,
      },
    },
    device_manager_config => {
      'DEFAULTS' => {
        'cassandra_server_list' => $cassandra_server_list,
        'disc_server_ip'        => $disc_server_ip,
        'rabbit_server'         => $rabbit_server,
        'redis_server'          => $redis_server,
        'zk_server_ip'          => $zk_server_ip,
      },
    },
    schema_config         => {
      'DEFAULTS' => {
        'cassandra_server_list' => $cassandra_server_list,
        'disc_server_ip'        => $disc_server_ip,
        'ifmap_password'        => $ifmap_password,
        'ifmap_server_ip'       => $ifmap_server_ip,
        'ifmap_username'        => $ifmap_username,
        'rabbit_server'         => $rabbit_server,
        'redis_server'          => $redis_server,
        'zk_server_ip'          => $zk_server_ip,
      },
    },
    discovery_config      => {
      'DEFAULTS' => {
        'cassandra_server_list' => $cassandra_server_list,
        'zk_server_ip'          => $zk_server_ip,
      },
    },
    svc_monitor_config    => {
      'DEFAULTS' => {
        'cassandra_server_list' => $cassandra_server_list,
        'disc_server_ip'        => $disc_server_ip,
        'ifmap_password'        => $ifmap_password,
        'ifmap_server_ip'       => $ifmap_server_ip,
        'ifmap_username'        => $ifmap_username,
        'rabbit_server'         => $rabbit_server,
        'redis_server'          => $redis_server,
      },
    },
  }
}
