# Copyright 2014 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: tripleo::loadbalancer
#
# Configure an HAProxy/keepalived loadbalancer for TripleO.
#
# === Parameters:
#
# [*manage_vip*]
#  Whether to configure keepalived to manage the VIPs or not.
#  Defaults to true
#
# [*haproxy_service_manage*]
#  Will be passed as value for service_manage to HAProxy module.
#  Defaults to true
#
# [*haproxy_global_maxconn*]
#  The value to use as maxconn in the HAProxy global config section.
#  Defaults to 20480
#
# [*haproxy_default_maxconn*]
#  The value to use as maxconn in the HAProxy default config section.
#  Defaults to 4096
#
# [*haproxy_default_timeout*]
#  The value to use as timeout in the HAProxy default config section.
#  Defaults to [ 'http-request 10s', 'queue 1m', 'connect 10s', 'client 1m', 'server 1m', 'check 10s' ]
#
# [*haproxy_listen_bind_param*]
#  A list of params to be added to the HAProxy listener bind directive. By
#  default the 'transparent' param is added but it should be cleared if
#  one of the *_virtual_ip addresses is a wildcard, eg. 0.0.0.0
#  Defaults to [ 'transparent' ]
#
# [*haproxy_member_options*]
#  The default options to use for the HAProxy balancer members.
#  Defaults to [ 'check', 'inter 2000', 'rise 2', 'fall 5' ]
#
# [*haproxy_log_address*]
#  The IPv4, IPv6 or filesystem socket path of the syslog server.
#  Defaults to '/dev/log'
#
# [*controller_host*]
#  (Deprecated)Host or group of hosts to load-balance the services
#  Can be a string or an array.
#  Defaults to undef
#
# [*controller_hosts*]
#  IPs of host or group of hosts to load-balance the services
#  Can be a string or an array.
#  Defaults to undef
#
# [*controller_hosts_names*]
#  Names of host or group of hosts to load-balance the services
#  Can be a string or an array.
#  Defaults to undef
#
# [*controller_virtual_ip*]
#  Control IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
#
# [*control_virtual_interface*]
#  Interface to bind the control VIP
#  Can be a string or an array.
#  Defaults to undef
#
# [*public_virtual_interface*]
#  Interface to bind the public VIP
#  Can be a string or an array.
#  Defaults to undef
#
# [*public_virtual_ip*]
#  Public IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
#
# [*internal_api_virtual_ip*]
#  Virtual IP on the internal API network.
#  A string.
#  Defaults to false
#
# [*storage_virtual_ip*]
#  Virtual IP on the storage network.
#  A string.
#  Defaults to false
#
# [*storage_mgmt_virtual_ip*]
#  Virtual IP on the storage mgmt network.
#  A string.
#  Defaults to false
#
# [*haproxy_stats_user*]
#  Username for haproxy stats authentication.
#  A string.
#  Defaults to 'admin'
#
# [*haproxy_stats_password*]
#  Password for haproxy stats authentication.  When set, authentication is
#  enabled on the haproxy stats endpoint.
#  A string.
#  Defaults to undef
#
# [*service_certificate*]
#  Filename of an HAProxy-compatible certificate and key file
#  When set, enables SSL on the public API endpoints using the specified file.
#  Defaults to undef
#
# [*internal_certificate*]
#  Filename of an HAProxy-compatible certificate and key file
#  When set, enables SSL on the internal API endpoints using the specified file.
#  Defaults to undef
#
# [*ssl_cipher_suite*]
#  The default string describing the list of cipher algorithms ("cipher suite")
#  that are negotiated during the SSL/TLS handshake for all "bind" lines. This
#  value comes from the Fedora system crypto policy.
#  Defaults to '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES'
#
# [*ssl_options*]
#  String that sets the default ssl options to force on all "bind" lines.
#  Defaults to 'no-sslv3'
#
# [*haproxy_stats_certificate*]
#  Filename of an HAProxy-compatible certificate and key file
#  When set, enables SSL on the haproxy stats endpoint using the specified file.
#  Defaults to undef
#
# [*keystone_admin*]
#  (optional) Enable or not Keystone Admin API binding
#  Defaults to false
#
# [*keystone_public*]
#  (optional) Enable or not Keystone Public API binding
#  Defaults to false
#
# [*neutron*]
#  (optional) Enable or not Neutron API binding
#  Defaults to false
#
# [*cinder*]
#  (optional) Enable or not Cinder API binding
#  Defaults to false
#
# [*manila*]
#  (optional) Enable or not Manila API binding
#  Defaults to false
#
# [*sahara*]
#  (optional) Enable or not Sahara API binding
#  defaults to false
#
# [*trove*]
#  (optional) Enable or not Trove API binding
#  defaults to false
#
# [*glance_api*]
#  (optional) Enable or not Glance API binding
#  Defaults to false
#
# [*glance_registry*]
#  (optional) Enable or not Glance registry binding
#  Defaults to false
#
# [*nova_osapi*]
#  (optional) Enable or not Nova API binding
#  Defaults to false
#
# [*nova_metadata*]
#  (optional) Enable or not Nova metadata binding
#  Defaults to false
#
# [*nova_novncproxy*]
#  (optional) Enable or not Nova novncproxy binding
#  Defaults to false
#
# [*ceilometer*]
#  (optional) Enable or not Ceilometer API binding
#  Defaults to false
#
# [*aodh*]
#  (optional) Enable or not Aodh API binding
#  Defaults to false
#
# [*gnocchi*]
#  (optional) Enable or not Gnocchi API binding
#  Defaults to false
#
# [*swift_proxy_server*]
#  (optional) Enable or not Swift API binding
#  Defaults to false
#
# [*heat_api*]
#  (optional) Enable or not Heat API binding
#  Defaults to false
#
# [*heat_cloudwatch*]
#  (optional) Enable or not Heat Cloudwatch API binding
#  Defaults to false
#
# [*heat_cfn*]
#  (optional) Enable or not Heat CFN API binding
#  Defaults to false
#
# [*horizon*]
#  (optional) Enable or not Horizon dashboard binding
#  Defaults to false
#
# [*ironic*]
#  (optional) Enable or not Ironic API binding
#  Defaults to false
#
# [*mysql*]
#  (optional) Enable or not MySQL Galera binding
#  Defaults to false
#
# [*mysql_clustercheck*]
#  (optional) Enable check via clustercheck for mysql
#  Defaults to false
#
# [*rabbitmq*]
#  (optional) Enable or not RabbitMQ binding
#  Defaults to false
#
# [*redis*]
#  (optional) Enable or not Redis binding
#  Defaults to false
#
# [*redis_password*]
#  (optional) Password for Redis authentication, eventually needed by the
#  specific monitoring we do from HAProxy for Redis
#  Defaults to undef
#
# [*midonet_api*]
#  (optional) Enable or not MidoNet API binding
#  Defaults to false
#
# [*service_ports*]
#  (optional) Hash that contains the values to override from the service ports
#  The available keys to modify the services' ports are:
#    'aodh_api_port' (Defaults to 8042)
#    'aodh_api_ssl_port' (Defaults to 13042)
#    'ceilometer_api_port' (Defaults to 8777)
#    'ceilometer_api_ssl_port' (Defaults to 13777)
#    'cinder_api_port' (Defaults to 8776)
#    'cinder_api_ssl_port' (Defaults to 13776)
#    'glance_api_port' (Defaults to 9292)
#    'glance_api_ssl_port' (Defaults to 13292)
#    'glance_registry_port' (Defaults to 9191)
#    'gnocchi_api_port' (Defaults to 8041)
#    'gnocchi_api_ssl_port' (Defaults to 13041)
#    'heat_api_port' (Defaults to 8004)
#    'heat_api_ssl_port' (Defaults to 13004)
#    'heat_cfn_port' (Defaults to 8000)
#    'heat_cfn_ssl_port' (Defaults to 13005)
#    'heat_cw_port' (Defaults to 8003)
#    'heat_cw_ssl_port' (Defaults to 13003)
#    'ironic_api_port' (Defaults to 6385)
#    'ironic_api_ssl_port' (Defaults to 13385)
#    'keystone_admin_api_port' (Defaults to 35357)
#    'keystone_admin_api_ssl_port' (Defaults to 13357)
#    'keystone_public_api_port' (Defaults to 5000)
#    'keystone_public_api_ssl_port' (Defaults to 13000)
#    'manila_api_port' (Defaults to 8786)
#    'manila_api_ssl_port' (Defaults to 13786)
#    'neutron_api_port' (Defaults to 9696)
#    'neutron_api_ssl_port' (Defaults to 13696)
#    'nova_api_port' (Defaults to 8774)
#    'nova_api_ssl_port' (Defaults to 13774)
#    'nova_metadata_port' (Defaults to 8775)
#    'nova_novnc_port' (Defaults to 6080)
#    'nova_novnc_ssl_port' (Defaults to 13080)
#    'sahara_api_port' (Defaults to 8386)
#    'sahara_api_ssl_port' (Defaults to 13386)
#    'swift_proxy_port' (Defaults to 8080)
#    'swift_proxy_ssl_port' (Defaults to 13808)
#    'trove_api_port' (Defaults to 8779)
#    'trove_api_ssl_port' (Defaults to 13779)
#  Defaults to {}
#
class tripleo::loadbalancer (
  $controller_virtual_ip,
  $control_virtual_interface,
  $public_virtual_interface,
  $public_virtual_ip,
  $internal_api_virtual_ip   = false,
  $storage_virtual_ip        = false,
  $storage_mgmt_virtual_ip   = false,
  $manage_vip                = true,
  $haproxy_service_manage    = true,
  $haproxy_global_maxconn    = 20480,
  $haproxy_default_maxconn   = 4096,
  $haproxy_default_timeout   = [ 'http-request 10s', 'queue 1m', 'connect 10s', 'client 1m', 'server 1m', 'check 10s' ],
  $haproxy_listen_bind_param = [ 'transparent' ],
  $haproxy_member_options    = [ 'check', 'inter 2000', 'rise 2', 'fall 5' ],
  $haproxy_log_address       = '/dev/log',
  $haproxy_stats_user        = 'admin',
  $haproxy_stats_password    = undef,
  $controller_host           = undef,
  $controller_hosts          = undef,
  $controller_hosts_names    = undef,
  $service_certificate       = undef,
  $internal_certificate      = undef,
  $ssl_cipher_suite          = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES',
  $ssl_options               = 'no-sslv3',
  $haproxy_stats_certificate = undef,
  $keystone_admin            = false,
  $keystone_public           = false,
  $neutron                   = false,
  $cinder                    = false,
  $sahara                    = false,
  $trove                     = false,
  $manila                    = false,
  $glance_api                = false,
  $glance_registry           = false,
  $nova_osapi                = false,
  $nova_metadata             = false,
  $nova_novncproxy           = false,
  $ceilometer                = false,
  $aodh                      = false,
  $gnocchi                   = false,
  $swift_proxy_server        = false,
  $heat_api                  = false,
  $heat_cloudwatch           = false,
  $heat_cfn                  = false,
  $horizon                   = false,
  $ironic                    = false,
  $mysql                     = false,
  $mysql_clustercheck        = false,
  $rabbitmq                  = false,
  $redis                     = false,
  $redis_password            = undef,
  $midonet_api               = false,
  $service_ports             = {}
) {
  warning('This class is going to be dropped during Newton cycle, replaced by tripleo::haproxy and tripleo::keepalived.')
  class { '::tripleo::haproxy':
    controller_virtual_ip     => $controller_virtual_ip,
    public_virtual_ip         => $public_virtual_ip,
    # Force to false because we already declare ::tripleo::keepalived later in this manifest to kep
    # old hieradata binding.
    keepalived                => false,
    haproxy_service_manage    => $haproxy_service_manage,
    haproxy_global_maxconn    => $haproxy_global_maxconn,
    haproxy_default_maxconn   => $haproxy_default_maxconn,
    haproxy_default_timeout   => $haproxy_default_timeout,
    haproxy_listen_bind_param => $haproxy_listen_bind_param,
    haproxy_member_options    => $haproxy_member_options,
    haproxy_log_address       => $haproxy_log_address,
    haproxy_stats_user        => $haproxy_stats_user,
    haproxy_stats_password    => $haproxy_stats_password,
    controller_host           => $controller_host,
    controller_hosts          => $controller_hosts,
    controller_hosts_names    => $controller_hosts_names,
    service_certificate       => $service_certificate,
    internal_certificate      => $internal_certificate,
    ssl_cipher_suite          => $ssl_cipher_suite,
    ssl_options               => $ssl_options,
    haproxy_stats_certificate => $haproxy_stats_certificate,
    keystone_admin            => $keystone_admin,
    keystone_public           => $keystone_public,
    neutron                   => $neutron,
    cinder                    => $cinder,
    sahara                    => $sahara,
    trove                     => $trove,
    manila                    => $manila,
    glance_api                => $glance_api,
    glance_registry           => $glance_registry,
    nova_osapi                => $nova_osapi,
    nova_metadata             => $nova_metadata,
    nova_novncproxy           => $nova_novncproxy,
    ceilometer                => $ceilometer,
    aodh                      => $aodh,
    gnocchi                   => $gnocchi,
    swift_proxy_server        => $swift_proxy_server,
    heat_api                  => $heat_api,
    heat_cloudwatch           => $heat_cloudwatch,
    heat_cfn                  => $heat_cfn,
    horizon                   => $horizon,
    ironic                    => $ironic,
    mysql                     => $mysql,
    mysql_clustercheck        => $mysql_clustercheck,
    rabbitmq                  => $rabbitmq,
    redis                     => $redis,
    redis_password            => $redis_password,
    midonet_api               => $midonet_api,
    service_ports             => $service_ports,
  }

  if $manage_vip {
    class { '::tripleo::keepalived':
      controller_virtual_ip     => $controller_virtual_ip,
      control_virtual_interface => $public_virtual_interface,
      public_virtual_interface  => $public_virtual_interface,
      public_virtual_ip         => $public_virtual_ip,
      internal_api_virtual_ip   => $internal_api_virtual_ip,
      storage_virtual_ip        => $storage_virtual_ip,
      storage_mgmt_virtual_ip   => $storage_mgmt_virtual_ip,
    }
  }
}
