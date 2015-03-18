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
# [*controller_host*]
#  Host or group of hosts to load-balance the services
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
# [*glance_api*]
#  (optional) Enable or not Glance API binding
#  Defaults to false
#
# [*glance_registry*]
#  (optional) Enable or not Glance registry binding
#  Defaults to false
#
# [*nova_ec2*]
#  (optional) Enable or not Nova EC2 API binding
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
# [*mysql*]
#  (optional) Enable or not MySQL Galera binding
#  Defaults to false
#
# [*rabbitmq*]
#  (optional) Enable or not RabbitMQ binding
#  Defaults to false
#
class tripleo::loadbalancer (
  $controller_host,
  $controller_virtual_ip,
  $control_virtual_interface,
  $public_virtual_interface,
  $public_virtual_ip,
  $keystone_admin            = false,
  $keystone_public           = false,
  $neutron                   = false,
  $cinder                    = false,
  $glance_api                = false,
  $glance_registry           = false,
  $nova_ec2                  = false,
  $nova_osapi                = false,
  $nova_metadata             = false,
  $nova_novncproxy           = false,
  $ceilometer                = false,
  $swift_proxy_server        = false,
  $heat_api                  = false,
  $heat_cloudwatch           = false,
  $heat_cfn                  = false,
  $horizon                   = false,
  $mysql                     = false,
  $rabbitmq                  = false,
) {

  case $::osfamily {
    'RedHat': {
      $keepalived_name_is_process = false
      $keepalived_vrrp_script     = 'systemctl status haproxy.service'
    } # RedHat
    'Debian': {
      $keepalived_name_is_process = true
      $keepalived_vrrp_script     = undef
    }
    default: {
      warning('Please configure keepalived defaults in tripleo::loadbalancer.')
      $keepalived_name_is_process = undef
      $keepalived_vrrp_script     = undef
    }
  }

  class { '::keepalived': }
  keepalived::vrrp_script { 'haproxy':
    name_is_process => $keepalived_name_is_process,
    script          => $keepalived_vrrp_script,
  }

  # KEEPALIVE INSTANCE CONTROL
  keepalived::instance { '51':
    interface    => $control_virtual_interface,
    virtual_ips  => [join([$controller_virtual_ip, ' dev ', $control_virtual_interface])],
    state        => 'MASTER',
    track_script => ['haproxy'],
    priority     => 101,
  }

  # KEEPALIVE INSTANCE PUBLIC
  keepalived::instance { '52':
    interface    => $public_virtual_interface,
    virtual_ips  => [join([$public_virtual_ip, ' dev ', $public_virtual_interface])],
    state        => 'MASTER',
    track_script => ['haproxy'],
    priority     => 101,
  }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }

  class { '::haproxy':
    global_options   => {
      'log'     => '/dev/log local0',
      'pidfile' => '/var/run/haproxy.pid',
      'user'    => 'haproxy',
      'group'   => 'haproxy',
      'daemon'  => '',
      'maxconn' => '4000',
    },
    defaults_options => {
      'mode'    => 'tcp',
      'log'     => 'global',
      'retries' => '3',
      'maxconn' => '150',
      'option'  => [ 'tcpka', 'tcplog' ],
      'timeout' => [ 'http-request 10s', 'queue 1m', 'connect 10s', 'client 1m', 'server 1m', 'check 10s' ],
    },
  }

  haproxy::listen { 'haproxy.stats':
    ipaddress        => '*',
    ports            => '1993',
    mode             => 'http',
    options          => {
      'stats' => 'enable',
    },
    collect_exported => false,
  }

  if $keystone_admin {
    haproxy::listen { 'keystone_admin':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 35357,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'keystone_admin':
      listening_service => 'keystone_admin',
      ports             => '35357',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $keystone_public {
    haproxy::listen { 'keystone_public':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 5000,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'keystone_public':
      listening_service => 'keystone_public',
      ports             => '5000',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $neutron {
    haproxy::listen { 'neutron':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 9696,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'neutron':
      listening_service => 'neutron',
      ports             => '9696',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $cinder {
    haproxy::listen { 'cinder':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8776,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'cinder':
      listening_service => 'cinder',
      ports             => '8776',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $glance_api {
    haproxy::listen { 'glance_api':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 9292,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'glance_api':
      listening_service => 'glance_api',
      ports             => '9292',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $glance_registry {
    haproxy::listen { 'glance_registry':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 9191,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'glance_registry':
      listening_service => 'glance_registry',
      ports             => '9191',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $nova_ec2 {
    haproxy::listen { 'nova_ec2':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8773,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'nova_ec2':
      listening_service => 'nova_ec2',
      ports             => '8773',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $nova_osapi {
    haproxy::listen { 'nova_osapi':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8774,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'nova_osapi':
      listening_service => 'nova_osapi',
      ports             => '8774',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $nova_metadata {
    haproxy::listen { 'nova_metadata':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8775,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'nova_metadata':
      listening_service => 'nova_metadata',
      ports             => '8775',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $nova_novncproxy {
    haproxy::listen { 'nova_novncproxy':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 6080,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'nova_novncproxy':
      listening_service => 'nova_novncproxy',
      ports             => '6080',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $ceilometer {
    haproxy::listen { 'ceilometer':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8777,
      collect_exported => false,
    }
    haproxy::balancermember { 'ceilometer':
      listening_service => 'ceilometer',
      ports             => '8777',
      ipaddresses       => $controller_host,
      options           => [],
    }
  }

  if $swift_proxy_server {
    haproxy::listen { 'swift_proxy_server':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8080,
      options          => {
        'option' => [ 'httpchk GET /info' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'swift_proxy_server':
      listening_service => 'swift_proxy_server',
      ports             => '8080',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $heat_api {
    haproxy::listen { 'heat_api':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8004,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'heat_api':
      listening_service => 'heat_api',
      ports             => '8004',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $heat_cloudwatch {
    haproxy::listen { 'heat_cloudwatch':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8003,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'heat_cloudwatch':
      listening_service => 'heat_cloudwatch',
      ports             => '8003',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $heat_cfn {
    haproxy::listen { 'heat_cfn':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 8000,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'heat_cfn':
      listening_service => 'heat_cfn',
      ports             => '8000',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $horizon {
    haproxy::listen { 'horizon':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 80,
      options          => {
        'option' => [ 'httpchk GET /' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'horizon':
      listening_service => 'horizon',
      ports             => '80',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $mysql {
    haproxy::listen { 'mysql':
      ipaddress        => [$controller_virtual_ip],
      ports            => 3306,
      options          => {
        'timeout' => [ 'client 0', 'server 0' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'mysql':
      listening_service => 'mysql',
      ports             => '3306',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

  if $rabbitmq {
    haproxy::listen { 'rabbitmq':
      ipaddress        => [$controller_virtual_ip, $public_virtual_ip],
      ports            => 5672,
      options          => {
        'timeout' => [ 'client 0', 'server 0' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'rabbitmq':
      listening_service => 'rabbitmq',
      ports             => '5672',
      ipaddresses       => $controller_host,
      options           => ['check', 'inter 2000', 'rise 2', 'fall 5'],
    }
  }

}
