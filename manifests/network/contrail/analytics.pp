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
# == Class: tripleo::network::contrail::analytics
#
# Configure Contrail Analytics services
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
# [*cassandra_server_list*]
#  (required) List IPs+port of Cassandra servers
#  Array of strings value.
#
# [*disc_server_ip*]
#  (required) IPv4 address of discovery server.
#  String (IPv4) value.
#
# [*host_ip*]
#  (required) host IP address of Analytics
#  String (IPv4) value.
#
# [*kafka_broker_list*]
#  (required) List IPs+port of kafka servers
#  Array of strings value.
#
# [*zk_server_ip*]
#  (required) List IPs+port of Zookeeper servers
#  Array of strings value.
#
# [*auth_port*]
#  (required) keystone port.
#  Integer value.
#  Defaults to 35357.
#
# [*auth_protocol*]
#  (required) authentication protocol.
#  String value.
#  Defaults to http.
#
# [*collector_http_server_port*]
#  (required) Collector http port
#  Integer value.
#  Defaults to 8089
#
# [*collector_sandesh_port*]
#  (required) Collector sandesh port
#  Integer value.
#  Defaults to 8086
#
# [*disc_server_port*]
#  (required) port Discovery server listens on.
#  Integer value.
#  Defaults to 5998
#
# [*http_server_port*]
#  (required) Analytics http port
#  Integer value.
#  Defaults to 8090
#
# [*insecure*]
#  (required) insecure mode.
#  Boolean value.
#  Defaults to false
#
# [*redis_server*]
#  (required) IPv4 address of redis server.
#  String (IPv4) value.
#  Defaults to '127.0.0.1'.
#
# [*redis_server_port*]
#  (required) port Redis server listens on.
#  Integer value.
#  Defaults to 6379
#
# [*rest_api_ip*]
#  (required) IP address Analytics rest interface listens on
#  String (IPv4) value.
#  Defaults to '0.0.0.0'
#
# [*rest_api_port*]
#  (required) Analytics rest port
#  Integer value.
#  Defaults to 8081
#
# [*memcached_servers*]
#  (optional) IPv4 address of memcached servers
#  String (IPv4) value + port
#  Defaults to '127.0.0.1:12111'
#
class tripleo::network::contrail::analytics(
  $admin_password = hiera('contrail::admin_password'),
  $admin_tenant_name = hiera('contrail::admin_tenant_name'),
  $admin_token = hiera('contrail::admin_token'),
  $admin_user = hiera('contrail::admin_user'),
  $auth_host = hiera('contrail::auth_host'),
  $cassandra_server_list = hiera('contrail::cassandra_server_list'),
  $disc_server_ip = hiera('contrail::disc_server_ip'),
  $host_ip,
  $kafka_broker_list = hiera('contrail::kafka_broker_list'),
  $zk_server_ip = hiera('contrail::zk_server_ip'),
  $auth_port = hiera('contrail::auth_port'),
  $auth_protocol = hiera('contrail::auth_protocol'),
  $collector_http_server_port = 8089,
  $collector_sandesh_port = 8086,
  $disc_server_port = hiera('contrail::disc_server_port'),
  $http_server_port = 8090,
  $insecure = hiera('contrail::insecure'),
  $redis_server = '127.0.0.1',
  $redis_server_port = 6379,
  $rest_api_ip = '0.0.0.0',
  $rest_api_port = 8081,
  $memcached_servers = hiera('contrail::memcached_server'),
)
{
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
  class {'::contrail::analytics':
    analytics_api_config  => {
      'DEFAULTS'  => {
        'cassandra_server_list' => $cassandra_server_list,
        'host_ip'               => $host_ip,
        'http_server_port'      => $http_server_port,
        'redis_server'          => $redis_server,
        'rest_api_ip'           => $rest_api_ip,
        'rest_api_port'         => $rest_api_port,
      },
      'DISCOVERY' => {
        'disc_server_ip'   => $disc_server_ip,
        'disc_server_port' => $disc_server_port,
      },
      'REDIS'     => {
        'redis_server_port' => $redis_server_port,
        'redis_query_port'  => $redis_server_port,
        'server'            => $redis_server,
      },
    },
    collector_config      => {
      'DEFAULTS'  => {
        'cassandra_server_list' => $cassandra_server_list,
        'disc_server_ip'        => $disc_server_ip,
        'hostip'                => $host_ip,
        'http_server_port'      => $collector_http_server_port,
        'kafka_broker_list'     => $kafka_broker_list,
        'zookeeper_server_list' => $zk_server_ip,
      },
      'COLLECTOR' => {
        'port' => $collector_sandesh_port,
      },
      'DISCOVERY' => {
        'port'   => $disc_server_port,
        'server' => $disc_server_ip,
      },
      'REDIS'     => {
        'port'   => $redis_server_port,
        'server' => $redis_server,
      },
    },
    query_engine_config   => {
      'DEFAULTS'  => {
        'cassandra_server_list' => $cassandra_server_list,
        'hostip'                => $host_ip,
      },
      'DISCOVERY' => {
        'port'   => $disc_server_port,
        'server' => $disc_server_ip,
      },
      'REDIS'     => {
        'port'   => $redis_server_port,
        'server' => $redis_server,
      },
    },
    snmp_collector_config => {
      'DEFAULTS'  => {
        'zk_server_ip' => $zk_server_ip,
      },
      'DISCOVERY' => {
        'disc_server_ip'   => $disc_server_ip,
        'disc_server_port' => $disc_server_port,
      },
    },
    topology_config       => {
      'DEFAULTS'  => {
        'zk_server_ip' => $zk_server_ip,
      },
      'DISCOVERY' => {
        'disc_server_ip'   => $disc_server_ip,
        'disc_server_port' => $disc_server_port,
      },
    },
  }
}
