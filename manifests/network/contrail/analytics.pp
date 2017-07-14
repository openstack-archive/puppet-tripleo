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
# [*host_ip*]
#  (required) host IP address of Analytics
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
# [*analytics_aaa_mode*]
#  (optional) analytics aaa mode parameter
#  String value.
#  Defaults to hiera('contrail::analytics_aaa_mode')
#
# [*auth_host*]
#  (optional) keystone server ip address
#  String (IPv4) value.
#  Defaults to hiera('contrail::auth_host')
#
# [*auth_port*]
#  (optional) keystone port.
#  Integer value.
#  Defaults to hiera('contrail::auth_port')
#
# [*auth_protocol*]
#  (optional) authentication protocol.
#  String value.
#  Defaults to hiera('contrail::auth_protocol')
#
# [*ca_file*]
#  (optional) ca file name
#  String value.
#  Defaults to hiera('contrail::service_certificate',false)
#
# [*cert_file*]
#  (optional) cert file name
#  String value.
#  Defaults to hiera('contrail::service_certificate',false)
#
# [*cassandra_server_list*]
#  (optional) List IPs+port of Cassandra servers
#  Array of strings value.
#  Defaults to hiera('contrail::cassandra_server_list')
#
# [*collector_http_server_port*]
#  (optional) Collector http port
#  Integer value.
#  Defaults to 8089
#
# [*collector_sandesh_port*]
#  (optional) Collector sandesh port
#  Integer value.
#  Defaults to 8086
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
# [*http_server_port*]
#  (optional) Analytics http port
#  Integer value.
#  Defaults to 8090
#
# [*insecure*]
#  (optional) insecure mode.
#  Boolean value.
#  Defaults to falsehiera('contrail::insecure')
#
# [*kafka_broker_list*]
#  (optional) List IPs+port of kafka servers
#  Array of strings value.
#  Defaults to hiera('contrail::kafka_broker_list')
#
# [*memcached_servers*]
#  (optional) IPv4 address of memcached servers
#  String (IPv4) value + port
#  Defaults to hiera('contrail::memcached_server')
#
# [*internal_vip*]
#  (optional) Public virtual IP address
#  String (IPv4) value
#  Defaults to hiera('internal_api_virtual_ip')
#
# [*rabbit_server*]
#  (optional) IPv4 addresses of rabbit server.
#  Array of String (IPv4) value.
#  Defaults to hiera('rabbitmq_node_ips')
#
# [*rabbit_user*]
#  (optional) Rabbit user
#  String value.
#  Defaults to hiera('contrail::rabbit_user')
#
# [*rabbit_password*]
#  (optional) Rabbit password
#  String value.
#  Defaults to hiera('contrail::rabbit_password')
#
# [*rabbit_port*]
#  (optional) port of rabbit server
#  String value.
#  Defaults to hiera('contrail::rabbit_port')
#
# [*redis_server*]
#  (optional) IPv4 address of redis server.
#  String (IPv4) value.
#  Defaults to '127.0.0.1'.
#
# [*redis_server_port*]
#  (optional) port Redis server listens on.
#  Integer value.
#  Defaults to 6379
#
# [*rest_api_ip*]
#  (optional) IP address Analytics rest interface listens on
#  String (IPv4) value.
#  Defaults to '0.0.0.0'
#
# [*rest_api_port*]
#  (optional) Analytics rest port
#  Integer value.
#  Defaults to 8081
#
# [*step*]
#  (optional) Step stack is in
#  Integer value.
#  Defaults to hiera('step')
#
# [*zk_server_ip*]
#  (optional) List IPs+port of Zookeeper servers
#  Array of strings value.
#  Defaults to hiera('contrail::zk_server_ip')
#
class tripleo::network::contrail::analytics(
  $step                       = Integer(hiera('step')),
  $admin_password             = hiera('contrail::admin_password'),
  $admin_tenant_name          = hiera('contrail::admin_tenant_name'),
  $admin_token                = hiera('contrail::admin_token'),
  $admin_user                 = hiera('contrail::admin_user'),
  $api_server                 = hiera('contrail_config_vip',hiera('internal_api_virtual_ip')),
  $api_port                   = hiera('contrail::api_port'),
  $auth_host                  = hiera('contrail::auth_host'),
  $auth_port                  = hiera('contrail::auth_port'),
  $auth_protocol              = hiera('contrail::auth_protocol'),
  $analytics_aaa_mode         = hiera('contrail::analytics_aaa_mode'),
  $cassandra_server_list      = hiera('contrail_analytics_database_node_ips'),
  $ca_file                    = hiera('contrail::service_certificate',false),
  $cert_file                  = hiera('contrail::service_certificate',false),
  $collector_http_server_port = hiera('contrail::analytics::collector_http_server_port'),
  $collector_sandesh_port     = hiera('contrail::analytics::collector_sandesh_port'),
  $disc_server_ip             = hiera('contrail_config_vip',hiera('internal_api_virtual_ip')),
  $disc_server_port           = hiera('contrail::disc_server_port'),
  $http_server_port           = hiera('contrail::analytics::http_server_port'),
  $host_ip                    = hiera('contrail::analytics::host_ip'),
  $insecure                   = hiera('contrail::insecure'),
  $kafka_broker_list          = hiera('contrail_analytics_database_node_ips'),
  $memcached_servers          = hiera('contrail::memcached_server'),
  $internal_vip               = hiera('internal_api_virtual_ip'),
  $rabbit_server              = hiera('rabbitmq_node_ips'),
  $rabbit_user                = hiera('contrail::rabbit_user'),
  $rabbit_password            = hiera('contrail::rabbit_password'),
  $rabbit_port                = hiera('contrail::rabbit_port'),
  $redis_server               = hiera('contrail::analytics::redis_server'),
  $redis_server_port          = hiera('contrail::analytics::redis_server_port'),
  $rest_api_ip                = hiera('contrail::analytics::rest_api_ip'),
  $rest_api_port              = hiera('contrail::analytics::rest_api_port'),
  $zk_server_ip               = hiera('contrail_database_node_ips'),
)
{
  $cassandra_server_list_9042 = join([join($cassandra_server_list, ':9042 '),':9042'],'')
  $kafka_broker_list_9092 = join([join($kafka_broker_list, ':9092 '),':9092'],'')
  $rabbit_server_list_5672 = join([join($rabbit_server, ':5672,'),':5672'],'')
  $redis_config = "bind ${host_ip} 127.0.0.1"
  $zk_server_ip_2181 = join([join($zk_server_ip, ':2181 '),':2181'],'')
  $zk_server_ip_2181_comma = join([join($zk_server_ip, ':2181,'),':2181'],'')

  if $auth_protocol == 'https' {
    $keystone_config = {
        'admin_password'    => $admin_password,
        'admin_tenant_name' => $admin_tenant_name,
        'admin_user'        => $admin_user,
        'auth_host'         => $auth_host,
        'auth_port'         => $auth_port,
        'auth_protocol'     => $auth_protocol,
        'insecure'          => $insecure,
        'certfile'          => $cert_file,
        'cafile'            => $ca_file,
    }
    $vnc_api_lib_config = {
      'auth' => {
        'AUTHN_SERVER'   => $auth_host,
        'AUTHN_PORT'     => $auth_port,
        'AUTHN_PROTOCOL' => $auth_protocol,
        'certfile'       => $cert_file,
        'cafile'         => $ca_file,
      },
    }
  } else {
    $keystone_config = {
        'admin_password'    => $admin_password,
        'admin_tenant_name' => $admin_tenant_name,
        'admin_user'        => $admin_user,
        'auth_host'         => $auth_host,
        'auth_port'         => $auth_port,
        'auth_protocol'     => $auth_protocol,
        'insecure'          => $insecure,
    }
    $vnc_api_lib_config = {
      'auth' => {
        'AUTHN_SERVER' => $auth_host,
      },
    }
  }
  if $step >= 3 {
    class {'::contrail::analytics':
      alarm_gen_config         => {
        'DEFAULTS'  => {
          'host_ip'              => $host_ip,
          'kafka_broker_list'    => $kafka_broker_list_9092,
          'rabbitmq_server_list' => $rabbit_server_list_5672,
          'rabbitmq_user'        => $rabbit_user,
          'rabbitmq_password'    => $rabbit_password,
          'zk_list'              => $zk_server_ip_2181,
        },
        'DISCOVERY' => {
          'disc_server_ip'   => $disc_server_ip,
          'disc_server_port' => $disc_server_port,
        },
      },
      analytics_nodemgr_config => {
        'DISCOVERY' => {
          'server' => $disc_server_ip,
          'port'   => $disc_server_port,
        },
      },
      analytics_api_config     => {
        'DEFAULTS'  => {
          'api_server'            => "${api_server}:${api_port}",
          'aaa_mode'              => $analytics_aaa_mode,
          'cassandra_server_list' => $cassandra_server_list_9042,
          'host_ip'               => $host_ip,
          'http_server_port'      => $http_server_port,
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
        'KEYSTONE'  => $keystone_config,
      },
      collector_config         => {
        'DEFAULT'   => {
          'cassandra_server_list' => $cassandra_server_list_9042,
          'hostip'                => $host_ip,
          'http_server_port'      => $collector_http_server_port,
          'kafka_broker_list'     => $kafka_broker_list_9092,
          'zookeeper_server_list' => $zk_server_ip_2181_comma,
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
      query_engine_config      => {
        'DEFAULT'   => {
          'cassandra_server_list' => $cassandra_server_list_9042,
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
      snmp_collector_config    => {
        'DEFAULTS'  => {
          'zookeeper' => $zk_server_ip_2181_comma,
        },
        'DISCOVERY' => {
          'disc_server_ip'   => $disc_server_ip,
          'disc_server_port' => $disc_server_port,
        },
        'KEYSTONE'  => $keystone_config,
      },
      redis_config             => $redis_config,
      topology_config          => {
        'DEFAULTS'  => {
          'zookeeper' => $zk_server_ip_2181_comma,
        },
        'DISCOVERY' => {
          'disc_server_ip'   => $disc_server_ip,
          'disc_server_port' => $disc_server_port,
        },
      },
      vnc_api_lib_config       => $vnc_api_lib_config,
      keystone_config          => {
        'KEYSTONE'     => $keystone_config,
      },
    }
  }
  if $step >= 5 {
    class {'::contrail::analytics::provision_analytics':
      api_address                => $api_server,
      api_port                   => $api_port,
      analytics_node_address     => $host_ip,
      analytics_node_name        => $::fqdn,
      keystone_admin_user        => $admin_user,
      keystone_admin_password    => $admin_password,
      keystone_admin_tenant_name => $admin_tenant_name,
      openstack_vip              => $auth_host,
    }
  }
}
