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

# == Class: tripleo::haproxy
#
# Configure HAProxy for TripleO.
#
# === Parameters:
#
# [*keepalived*]
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
# [*controller_hosts*]
#  IPs of host or group of hosts to load-balance the services
#  Can be a string or an array.
#  Defaults tohiera('controller_node_ips')
#
# [*controller_hosts_names*]
#  Names of host or group of hosts to load-balance the services
#  Can be a string or an array.
#  Defaults to hiera('controller_node_names', undef)
#
# [*controller_virtual_ip*]
#  Control IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
#
# [*public_virtual_ip*]
#  Public IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
# [*haproxy_stats_user*]
#
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
#  Defaults to hiera('keystone_enabled', false)
#
# [*keystone_public*]
#  (optional) Enable or not Keystone Public API binding
#  Defaults to hiera('keystone_enabled', false)
#
# [*neutron*]
#  (optional) Enable or not Neutron API binding
#  Defaults to hiera('neutron_api_enabled', false)
#
# [*cinder*]
#  (optional) Enable or not Cinder API binding
#  Defaults to hiera('cinder_api_enabled', false)
#
# [*manila*]
#  (optional) Enable or not Manila API binding
#  Defaults to hiera('manila_api_enabled', false)
#
# [*sahara*]
#  (optional) Enable or not Sahara API binding
#  defaults to hiera('sahara_api_enabled', false)
#
# [*trove*]
#  (optional) Enable or not Trove API binding
#  defaults to hiera('trove_api_enabled', false)
#
# [*glance_api*]
#  (optional) Enable or not Glance API binding
#  Defaults to hiera('glance_api_enabled', false)
#
# [*glance_registry*]
#  (optional) Enable or not Glance registry binding
#  Defaults to hiera('glance_registry_enabled', false)
#
# [*nova_osapi*]
#  (optional) Enable or not Nova API binding
#  Defaults to hiera('nova_api_enabled', false)
#
# [*nova_metadata*]
#  (optional) Enable or not Nova metadata binding
#  Defaults to hiera('nova_api_enabled', false)
#
# [*nova_novncproxy*]
#  (optional) Enable or not Nova novncproxy binding
#  Defaults to hiera('nova_vncproxy_enabled', false)
#
# [*ceilometer*]
#  (optional) Enable or not Ceilometer API binding
#  Defaults to hiera('ceilometer_api_enabled', false)
#
# [*aodh*]
#  (optional) Enable or not Aodh API binding
#  Defaults to hiera('aodh_api_enabled', false)
#
# [*gnocchi*]
#  (optional) Enable or not Gnocchi API binding
#  Defaults to hiera('gnocchi_api_enabled', false)
#
# [*mistral*]
#  (optional) Enable or not Mistral API binding
#  Defaults to hiera('mistral_api_enabled', false)
#
# [*swift_proxy_server*]
#  (optional) Enable or not Swift API binding
#  Defaults to hiera('swift_proxy_enabled', false)
#
# [*heat_api*]
#  (optional) Enable or not Heat API binding
#  Defaults to hiera('heat_api_enabled', false)
#
# [*heat_cloudwatch*]
#  (optional) Enable or not Heat Cloudwatch API binding
#  Defaults to hiera('heat_api_cloudwatch_enabled', false)
#
# [*heat_cfn*]
#  (optional) Enable or not Heat CFN API binding
#  Defaults to hiera('heat_api_cfn_enabled', false)
#
# [*horizon*]
#  (optional) Enable or not Horizon dashboard binding
#  Defaults to hiera('horizon_enabled', false)
#
# [*ironic*]
#  (optional) Enable or not Ironic API binding
#  Defaults to hiera('ironic_enabled', false)
#
# [*ironic_inspector*]
#  (optional) Enable or not Ironic Inspector API binding
#  Defaults to hiera('ironic_inspector_enabled', false)
#
# [*mysql*]
#  (optional) Enable or not MySQL Galera binding
#  Defaults to hiera('mysql_enabled', false)
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
#  Defaults to hiera('redis_enabled', false)
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
# [*zaqar_api*]
#  (optional) Enable or not Zaqar Api binding
#  Defaults to hiera('zaqar_api_enabled', false)
#
# [*ceph_rgw*]
#  (optional) Enable or not Ceph RadosGW binding
#  Defaults to hiera('ceph_rgw_enabled', false)
#
# [*opendaylight*]
#  (optional) Enable or not OpenDaylight binding
#  Defaults to hiera('opendaylight_api_enabled', false)
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
#    'mistral_api_port' (Defaults to 8989)
#    'mistral_api_ssl_port' (Defaults to 13989)
#    'heat_api_port' (Defaults to 8004)
#    'heat_api_ssl_port' (Defaults to 13004)
#    'heat_cfn_port' (Defaults to 8000)
#    'heat_cfn_ssl_port' (Defaults to 13005)
#    'heat_cw_port' (Defaults to 8003)
#    'heat_cw_ssl_port' (Defaults to 13003)
#    'ironic_api_port' (Defaults to 6385)
#    'ironic_api_ssl_port' (Defaults to 13385)
#    'ironic_inspector_port' (Defaults to 5050)
#    'ironic_inspector_ssl_port' (Defaults to 13050)
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
#    'zaqar_api_port' (Defaults to 8888)
#    'zaqar_api_ssl_port' (Defaults to 13888)
#    'ceph_rgw_port' (Defaults to 8080)
#    'ceph_rgw_ssl_port' (Defaults to 13808)
#  Defaults to {}
#
class tripleo::haproxy (
  $controller_virtual_ip,
  $public_virtual_ip,
  $keepalived                = true,
  $haproxy_service_manage    = true,
  $haproxy_global_maxconn    = 20480,
  $haproxy_default_maxconn   = 4096,
  $haproxy_default_timeout   = [ 'http-request 10s', 'queue 1m', 'connect 10s', 'client 1m', 'server 1m', 'check 10s' ],
  $haproxy_listen_bind_param = [ 'transparent' ],
  $haproxy_member_options    = [ 'check', 'inter 2000', 'rise 2', 'fall 5' ],
  $haproxy_log_address       = '/dev/log',
  $haproxy_stats_user        = 'admin',
  $haproxy_stats_password    = undef,
  $controller_hosts          = hiera('controller_node_ips'),
  $controller_hosts_names    = hiera('controller_node_names', undef),
  $service_certificate       = undef,
  $internal_certificate      = undef,
  $ssl_cipher_suite          = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES',
  $ssl_options               = 'no-sslv3',
  $haproxy_stats_certificate = undef,
  $keystone_admin            = hiera('keystone_enabled', false),
  $keystone_public           = hiera('keystone_enabled', false),
  $neutron                   = hiera('neutron_api_enabled', false),
  $cinder                    = hiera('cinder_api_enabled', false),
  $manila                    = hiera('manila_api_enabled', false),
  $sahara                    = hiera('sahara_api_enabled', false),
  $trove                     = hiera('trove_api_enabled', false),
  $glance_api                = hiera('glance_api_enabled', false),
  $glance_registry           = hiera('glance_registry_enabled', false),
  $nova_osapi                = hiera('nova_api_enabled', false),
  $nova_metadata             = hiera('nova_api_enabled', false),
  $nova_novncproxy           = hiera('nova_vncproxy_enabled', false),
  $ceilometer                = hiera('ceilometer_api_enabled', false),
  $aodh                      = hiera('aodh_api_enabled', false),
  $gnocchi                   = hiera('gnocchi_api_enabled', false),
  $mistral                   = hiera('mistral_api_enabled', false),
  $swift_proxy_server        = hiera('swift_proxy_enabled', false),
  $heat_api                  = hiera('heat_api_enabled', false),
  $heat_cloudwatch           = hiera('heat_api_cloudwatch_enabled', false),
  $heat_cfn                  = hiera('heat_api_cfn_enabled', false),
  $horizon                   = hiera('horizon_enabled', false),
  $ironic                    = hiera('ironic_api_enabled', false),
  $ironic_inspector          = hiera('ironic_inspector_enabled', false),
  $mysql                     = hiera('mysql_enabled', false),
  $mysql_clustercheck        = false,
  $rabbitmq                  = false,
  $redis                     = hiera('redis_enabled', false),
  $redis_password            = undef,
  $midonet_api               = false,
  $zaqar_api                 = hiera('zaqar_api_enabled', false),
  $ceph_rgw                  = hiera('ceph_rgw_enabled', false),
  $opendaylight              = hiera('opendaylight_api_enabled', false),
  $service_ports             = {}
) {
  $default_service_ports = {
    aodh_api_port => 8042,
    aodh_api_ssl_port => 13042,
    ceilometer_api_port => 8777,
    ceilometer_api_ssl_port => 13777,
    cinder_api_port => 8776,
    cinder_api_ssl_port => 13776,
    glance_api_port => 9292,
    glance_api_ssl_port => 13292,
    glance_registry_port => 9191,
    gnocchi_api_port => 8041,
    gnocchi_api_ssl_port => 13041,
    mistral_api_port => 8989,
    mistral_api_ssl_port => 13989,
    heat_api_port => 8004,
    heat_api_ssl_port => 13004,
    heat_cfn_port => 8000,
    heat_cfn_ssl_port => 13005,
    heat_cw_port => 8003,
    heat_cw_ssl_port => 13003,
    ironic_api_port => 6385,
    ironic_api_ssl_port => 13385,
    ironic_inspector_port => 5050,
    ironic_inspector_ssl_port => 13050,
    keystone_admin_api_port => 35357,
    keystone_admin_api_ssl_port => 13357,
    keystone_public_api_port => 5000,
    keystone_public_api_ssl_port => 13000,
    manila_api_port => 8786,
    manila_api_ssl_port => 13786,
    neutron_api_port => 9696,
    neutron_api_ssl_port => 13696,
    nova_api_port => 8774,
    nova_api_ssl_port => 13774,
    nova_metadata_port => 8775,
    nova_novnc_port => 6080,
    nova_novnc_ssl_port => 13080,
    sahara_api_port => 8386,
    sahara_api_ssl_port => 13386,
    swift_proxy_port => 8080,
    swift_proxy_ssl_port => 13808,
    trove_api_port => 8779,
    trove_api_ssl_port => 13779,
    zaqar_api_port => 8888,
    zaqar_api_ssl_port => 13888,
    ceph_rgw_port => 8080,
    ceph_rgw_ssl_port => 13808,
  }
  $ports = merge($default_service_ports, $service_ports)

  $controller_hosts_real = any2array(split($controller_hosts, ','))
  if ! $controller_hosts_names {
    $controller_hosts_names_real = $controller_hosts_real
  } else {
    $controller_hosts_names_real = downcase(any2array(split($controller_hosts_names, ',')))
  }

  # This code will be removed once we switch undercloud and overcloud to use both haproxy & keepalived roles.
  if $keepalived {
    include ::tripleo::keepalived
  }

  # TODO(bnemec): When we have support for SSL on private and admin endpoints,
  # have the haproxy stats endpoint use that certificate by default.
  if $haproxy_stats_certificate {
    $haproxy_stats_bind_certificate = $haproxy_stats_certificate
  }

  $horizon_vip = hiera('horizon_vip', $controller_virtual_ip)
  if $service_certificate {
    # NOTE(jaosorior): If the horizon_vip and the public_virtual_ip are the
    # same, the first option takes precedence. Which is the case when network
    # isolation is not enabled. This is not a problem as both options are
    # identical. If network isolation is enabled, this works correctly and
    # will add a TLS binding to both the horizon_vip and the
    # public_virtual_ip.
    # Even though for the public_virtual_ip the port 80 is listening, we
    # redirect to https in the horizon_options below.
    $horizon_bind_opts = {
      "${horizon_vip}:80"        => $haproxy_listen_bind_param,
      "${horizon_vip}:443"       => union($haproxy_listen_bind_param, ['ssl', 'crt', $service_certificate]),
      "${public_virtual_ip}:80"  => $haproxy_listen_bind_param,
      "${public_virtual_ip}:443" => union($haproxy_listen_bind_param, ['ssl', 'crt', $service_certificate]),
    }
    $horizon_options = {
      'cookie'   => 'SERVERID insert indirect nocache',
      'rsprep'   => '^Location:\ http://(.*) Location:\ https://\1',
      # NOTE(jaosorior): We always redirect to https for the public_virtual_ip.
      'redirect' => "scheme https code 301 if { hdr(host) -i ${public_virtual_ip} } !{ ssl_fc }",
      'option'   => 'forwardfor',
    }
  } else {
    $horizon_bind_opts = {
      "${horizon_vip}:80" => $haproxy_listen_bind_param,
      "${public_virtual_ip}:80" => $haproxy_listen_bind_param,
    }
    $horizon_options = {
      'cookie' => 'SERVERID insert indirect nocache',
      'option' => 'forwardfor',
    }
  }

  if $haproxy_stats_bind_certificate {
    $haproxy_stats_bind_opts = {
      "${controller_virtual_ip}:1993" => union($haproxy_listen_bind_param, ['ssl', 'crt', $haproxy_stats_bind_certificate]),
    }
  } else {
    $haproxy_stats_bind_opts = {
      "${controller_virtual_ip}:1993" => $haproxy_listen_bind_param,
    }
  }

  $mysql_vip = hiera('mysql_vip', $controller_virtual_ip)
  $mysql_bind_opts = {
    "${mysql_vip}:3306" => $haproxy_listen_bind_param,
  }

  $rabbitmq_vip = hiera('rabbitmq_vip', $controller_virtual_ip)
  $rabbitmq_bind_opts = {
    "${rabbitmq_vip}:5672" => $haproxy_listen_bind_param,
  }

  $redis_vip = hiera('redis_vip', $controller_virtual_ip)
  $redis_bind_opts = {
    "${redis_vip}:6379" => $haproxy_listen_bind_param,
  }

  class { '::haproxy':
    service_manage   => $haproxy_service_manage,
    global_options   => {
      'log'                      => "${haproxy_log_address} local0",
      'pidfile'                  => '/var/run/haproxy.pid',
      'user'                     => 'haproxy',
      'group'                    => 'haproxy',
      'daemon'                   => '',
      'maxconn'                  => $haproxy_global_maxconn,
      'ssl-default-bind-ciphers' => $ssl_cipher_suite,
      'ssl-default-bind-options' => $ssl_options,
    },
    defaults_options => {
      'mode'    => 'tcp',
      'log'     => 'global',
      'retries' => '3',
      'timeout' => $haproxy_default_timeout,
      'maxconn' => $haproxy_default_maxconn,
    },
  }

  Tripleo::Haproxy::Endpoint {
    haproxy_listen_bind_param => $haproxy_listen_bind_param,
    member_options            => $haproxy_member_options,
    public_certificate        => $service_certificate,
    internal_certificate      => $internal_certificate,
  }

  $stats_base = ['enable', 'uri /']
  if $haproxy_stats_password {
    $stats_config = union($stats_base, ["auth ${haproxy_stats_user}:${haproxy_stats_password}"])
  } else {
    $stats_config = $stats_base
  }
  haproxy::listen { 'haproxy.stats':
    bind             => $haproxy_stats_bind_opts,
    mode             => 'http',
    options          => {
      'stats' => $stats_config,
    },
    collect_exported => false,
  }

  if $keystone_admin {
    ::tripleo::haproxy::endpoint { 'keystone_admin':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('keystone_admin_api_vip', $controller_virtual_ip),
      service_port      => $ports[keystone_admin_api_port],
      ip_addresses      => hiera('keystone_admin_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[keystone_admin_api_ssl_port],
    }
  }

  if $keystone_public {
    $keystone_listen_opts = {
      'http-request' => [
        'set-header X-Forwarded-Proto https if { ssl_fc }',
        'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
    }
    if $service_certificate {
      $keystone_public_tls_listen_opts = {
        'rsprep'       => '^Location:\ http://(.*) Location:\ https://\1',
        # NOTE(jaosorior): We always redirect to https for the public_virtual_ip.
        'redirect'     => "scheme https code 301 if { hdr(host) -i ${public_virtual_ip} } !{ ssl_fc }",
        'option'       => 'forwardfor',
      }
    } else {
      $keystone_public_tls_listen_opts = {}
    }
    ::tripleo::haproxy::endpoint { 'keystone_public':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('keystone_public_api_vip', $controller_virtual_ip),
      service_port      => $ports[keystone_public_api_port],
      ip_addresses      => hiera('keystone_public_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      listen_options    => merge($keystone_listen_opts, $keystone_public_tls_listen_opts),
      public_ssl_port   => $ports[keystone_public_api_ssl_port],
    }
  }

  if $neutron {
    ::tripleo::haproxy::endpoint { 'neutron':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('neutron_api_vip', $controller_virtual_ip),
      service_port      => $ports[neutron_api_port],
      ip_addresses      => hiera('neutron_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[neutron_api_ssl_port],
    }
  }

  if $cinder {
    ::tripleo::haproxy::endpoint { 'cinder':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('cinder_api_vip', $controller_virtual_ip),
      service_port      => $ports[cinder_api_port],
      ip_addresses      => hiera('cinder_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[cinder_api_ssl_port],
    }
  }

  if $manila {
    ::tripleo::haproxy::endpoint { 'manila':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('manila_api_vip', $controller_virtual_ip),
      service_port      => $ports[manila_api_port],
      ip_addresses      => hiera('manila_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[manila_api_ssl_port],
    }
  }

  if $sahara {
    ::tripleo::haproxy::endpoint { 'sahara':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('sahara_api_vip', $controller_virtual_ip),
      service_port      => $ports[sahara_api_port],
      ip_addresses      => hiera('sahara_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[sahara_api_ssl_port],
    }
  }

  if $trove {
    ::tripleo::haproxy::endpoint { 'trove':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('trove_api_vip', $controller_virtual_ip),
      service_port      => $ports[trove_api_port],
      ip_addresses      => hiera('trove_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[trove_api_ssl_port],
    }
  }

  if $glance_api {
    ::tripleo::haproxy::endpoint { 'glance_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('glance_api_vip', $controller_virtual_ip),
      service_port      => $ports[glance_api_port],
      ip_addresses      => hiera('glance_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[glance_api_ssl_port],
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
    }
  }

  if $glance_registry {
    ::tripleo::haproxy::endpoint { 'glance_registry':
      internal_ip  => hiera('glance_registry_vip', $controller_virtual_ip),
      service_port => $ports[glance_registry_port],
      ip_addresses => hiera('glance_registry_node_ips', $controller_hosts_real),
      server_names => $controller_hosts_names_real,
    }
  }

  $nova_api_vip = hiera('nova_api_vip', $controller_virtual_ip)
  if $nova_osapi {
    ::tripleo::haproxy::endpoint { 'nova_osapi':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $nova_api_vip,
      service_port      => $ports[nova_api_port],
      ip_addresses      => hiera('nova_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[nova_api_ssl_port],
    }
  }

  if $nova_metadata {
    ::tripleo::haproxy::endpoint { 'nova_metadata':
      internal_ip  => hiera('nova_metadata_vip', $controller_virtual_ip),
      service_port => $ports[nova_metadata_port],
      ip_addresses => hiera('nova_metadata_node_ips', $controller_hosts_real),
      server_names => $controller_hosts_names_real,
    }
  }

  if $nova_novncproxy {
    ::tripleo::haproxy::endpoint { 'nova_novncproxy':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $nova_api_vip,
      service_port      => $ports[nova_novnc_port],
      ip_addresses      => hiera('nova_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      listen_options    => {
        'balance' => 'source',
        'timeout' => [ 'tunnel 1h' ],
      },
      public_ssl_port   => $ports[nova_novnc_ssl_port],
    }
  }

  if $ceilometer {
    ::tripleo::haproxy::endpoint { 'ceilometer':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ceilometer_api_vip', $controller_virtual_ip),
      service_port      => $ports[ceilometer_api_port],
      ip_addresses      => hiera('ceilometer_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[ceilometer_api_ssl_port],
    }
  }

  if $aodh {
    ::tripleo::haproxy::endpoint { 'aodh':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('aodh_api_vip', $controller_virtual_ip),
      service_port      => $ports[aodh_api_port],
      ip_addresses      => hiera('aodh_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[aodh_api_ssl_port],
    }
  }

  if $gnocchi {
    ::tripleo::haproxy::endpoint { 'gnocchi':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('gnocchi_api_vip', $controller_virtual_ip),
      service_port      => $ports[gnocchi_api_port],
      ip_addresses      => hiera('gnocchi_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[gnocchi_api_ssl_port],
    }
  }

  if $mistral {
    ::tripleo::haproxy::endpoint { 'mistral':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('mistral_api_vip', $controller_virtual_ip),
      service_port      => $ports[mistral_api_port],
      ip_addresses      => hiera('mistral_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[mistral_api_ssl_port],
    }
  }

  if $swift_proxy_server {
    ::tripleo::haproxy::endpoint { 'swift_proxy_server':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('swift_proxy_vip', $controller_virtual_ip),
      service_port      => $ports[swift_proxy_port],
      ip_addresses      => hiera('swift_proxy_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[swift_proxy_ssl_port],
    }
  }

  $heat_api_vip = hiera('heat_api_vip', $controller_virtual_ip)
  $heat_ip_addresses = hiera('heat_api_node_ips', $controller_hosts_real)
  $heat_base_options = {
    'http-request' => [
      'set-header X-Forwarded-Proto https if { ssl_fc }',
      'set-header X-Forwarded-Proto http if !{ ssl_fc }']}
  if $service_certificate {
    $heat_ssl_options = {
      'rsprep' => "^Location:\\ http://${public_virtual_ip}(.*) Location:\\ https://${public_virtual_ip}\\1",
    }
    $heat_options = merge($heat_base_options, $heat_ssl_options)
  } else {
    $heat_options = $heat_base_options
  }

  if $heat_api {
    ::tripleo::haproxy::endpoint { 'heat_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $heat_api_vip,
      service_port      => $ports[heat_api_port],
      ip_addresses      => $heat_ip_addresses,
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      listen_options    => $heat_options,
      public_ssl_port   => $ports[heat_api_ssl_port],
    }
  }

  if $heat_cloudwatch {
    ::tripleo::haproxy::endpoint { 'heat_cloudwatch':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $heat_api_vip,
      service_port      => $ports[heat_cw_port],
      ip_addresses      => $heat_ip_addresses,
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      listen_options    => $heat_options,
      public_ssl_port   => $ports[heat_cw_ssl_port],
    }
  }

  if $heat_cfn {
    ::tripleo::haproxy::endpoint { 'heat_cfn':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $heat_api_vip,
      service_port      => $ports[heat_cfn_port],
      ip_addresses      => $heat_ip_addresses,
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      listen_options    => $heat_options,
      public_ssl_port   => $ports[heat_cfn_ssl_port],
    }
  }

  if $horizon {
    haproxy::listen { 'horizon':
      bind             => $horizon_bind_opts,
      options          => $horizon_options,
      mode             => 'http',
      collect_exported => false,
    }
    haproxy::balancermember { 'horizon':
      listening_service => 'horizon',
      ports             => '80',
      ipaddresses       => hiera('horizon_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      options           => union($haproxy_member_options, ["cookie ${::hostname}"]),
    }
  }

  if $ironic {
    ::tripleo::haproxy::endpoint { 'ironic':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ironic_api_vip', $controller_virtual_ip),
      service_port      => $ports[ironic_api_port],
      ip_addresses      => hiera('ironic_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[ironic_api_ssl_port],
    }
  }

  if $ironic_inspector {
    ::tripleo::haproxy::endpoint { 'ironic-inspector':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ironic_inspector_vip', $controller_virtual_ip),
      service_port      => $ports[ironic_inspector_port],
      ip_addresses      => hiera('ironic_inspector_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[ironic_inspector_ssl_port],
    }
  }

  if $mysql_clustercheck {
    $mysql_listen_options = {
      'option'         => [ 'tcpka', 'httpchk' ],
      'timeout client' => '90m',
      'timeout server' => '90m',
      'stick-table'    => 'type ip size 1000',
      'stick'          => 'on dst',
    }
    $mysql_member_options = union($haproxy_member_options, ['backup', 'port 9200', 'on-marked-down shutdown-sessions'])
  } else {
    $mysql_listen_options = {
      'timeout client' => '90m',
      'timeout server' => '90m',
    }
    $mysql_member_options = union($haproxy_member_options, ['backup'])
  }

  if $mysql {
    haproxy::listen { 'mysql':
      bind             => $mysql_bind_opts,
      options          => $mysql_listen_options,
      collect_exported => false,
    }
    haproxy::balancermember { 'mysql-backup':
      listening_service => 'mysql',
      ports             => '3306',
      ipaddresses       => hiera('mysql_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      options           => $mysql_member_options,
    }
  }

  if $rabbitmq {
    haproxy::listen { 'rabbitmq':
      bind             => $rabbitmq_bind_opts,
      options          => {
        'option'  => [ 'tcpka' ],
        'timeout' => [ 'client 0', 'server 0' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'rabbitmq':
      listening_service => 'rabbitmq',
      ports             => '5672',
      ipaddresses       => hiera('rabbitmq_network', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      options           => $haproxy_member_options,
    }
  }

  if $redis {
    if $redis_password {
      $redis_tcp_check_options = ["send AUTH\\ ${redis_password}\\r\\n"]
    } else {
      $redis_tcp_check_options = []
    }
    haproxy::listen { 'redis':
      bind             => $redis_bind_opts,
      options          => {
        'balance'   => 'first',
        'option'    => ['tcp-check',],
        'tcp-check' => union($redis_tcp_check_options, ['send PING\r\n',
                                                        'expect string +PONG',
                                                        'send info\ replication\r\n',
                                                        'expect string role:master',
                                                        'send QUIT\r\n',
                                                        'expect string +OK']),
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'redis':
      listening_service => 'redis',
      ports             => '6379',
      ipaddresses       => hiera('redis_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      options           => $haproxy_member_options,
    }
  }

  $midonet_api_vip = hiera('midonet_api_vip', $controller_virtual_ip)
  $midonet_bind_opts = {
    "${midonet_api_vip}:8081" => [],
    "${public_virtual_ip}:8081" => [],
  }

  if $midonet_api {
    haproxy::listen { 'midonet_api':
      bind             => $midonet_bind_opts,
      collect_exported => false,
    }
    haproxy::balancermember { 'midonet_api':
      listening_service => 'midonet_api',
      ports             => '8081',
      ipaddresses       => hiera('midonet_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      options           => $haproxy_member_options,
    }
  }
  if $zaqar_api {
    ::tripleo::haproxy::endpoint { 'zaqar_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('zaqar_api_vip', $controller_virtual_ip),
      service_port      => $ports[zaqar_api_port],
      ip_addresses      => hiera('zaqar_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      public_ssl_port   => $ports[zaqar_api_ssl_port],
    }
  }

  if $ceph_rgw {
    ::tripleo::haproxy::endpoint { 'ceph_rgw':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ceph_rgw_vip', $controller_virtual_ip),
      service_port      => $ports[ceph_rgw_port],
      ip_addresses      => hiera('ceph_rgw_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      public_ssl_port   => $ports[ceph_rgw_ssl_port],
    }
  }

  $opendaylight_api_vip = hiera('opendaylight_api_vip', $controller_virtual_ip)
  $opendaylight_bind_opts = {
    "${opendaylight_api_vip}:8081" => [],
    "${public_virtual_ip}:8081" => [],
  }

  if $opendaylight {
    haproxy::listen { 'opendaylight':
      bind             => $opendaylight_bind_opts,
      options          => {
        'balance' => 'source',
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'opendaylight':
      listening_service => 'opendaylight',
      ports             => '8081',
      ipaddresses       => hiera('opendaylight_api_node_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }
}
