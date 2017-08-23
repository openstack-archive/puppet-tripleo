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
# == Class: tripleo::profile::base::database::redis
#
# Redis profile for tripleo
#
# === Parameters
#
# [*bootstrap_nodeid*]
#   (Optional) Hostname of Redis master
#   Defaults to hiera('bootstrap_nodeid')
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Example with hiera:
#     redis_certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "haproxy/<overcloud controller fqdn>"
#   Defaults to hiera('redis_certificate_specs', {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*redis_network*]
#   (Optional) The network name where the redis endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('redis_network', undef)
#
# [*redis_node_ips*]
#   (Optional) List of Redis node ips
#   Defaults to hiera('redis_node_ips')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. required only used if
#   enable_internal_tls is set.
#   defaults to undef
#
# [*tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   defaults to 6379
#
class tripleo::profile::base::database::redis (
  $bootstrap_nodeid    = hiera('bootstrap_nodeid'),
  $certificate_specs  = hiera('redis_certificate_specs', {}),
  $enable_internal_tls = hiera('enable_internal_tls', false),
  $redis_network       = hiera('redis_network', undef),
  $redis_node_ips      = hiera('redis_node_ips'),
  $step                = Integer(hiera('step')),
  $tls_proxy_bind_ip   = undef,
  $tls_proxy_fqdn      = undef,
  $tls_proxy_port      = 6379,
) {
  if $step >= 2 {
    if $enable_internal_tls {
      if !$redis_network {
        fail('redis_network is not set in the hieradata.')
      }
      if !$tls_proxy_bind_ip {
        fail('tls_proxy_bind_ip is not set in the hieradata.')
      }
      if !$tls_proxy_fqdn {
        fail('tls_proxy_fqdn is required if internal TLS is enabled.')
      }
      $tls_certfile = $certificate_specs['service_certificate']
      $tls_keyfile = $certificate_specs['service_key']

      include ::tripleo::stunnel

      ::tripleo::stunnel::service_proxy { 'redis':
        accept_host  => $tls_proxy_bind_ip,
        accept_port  => $tls_proxy_port,
        connect_port => $tls_proxy_port,
        certificate  => $tls_certfile,
        key          => $tls_keyfile,
        notify       => Class['::redis'],
      }
    }
    if downcase($bootstrap_nodeid) == $::hostname {
      $slaveof = undef
    } else {
      $slaveof = "${bootstrap_nodeid} 6379"
    }
    class { '::redis' :
      slaveof => $slaveof,
    }

    if count($redis_node_ips) > 1 {
      Class['::tripleo::redis_notification'] -> Service['redis-sentinel']
      include ::redis::sentinel
      include ::tripleo::redis_notification
    }
  }
}
