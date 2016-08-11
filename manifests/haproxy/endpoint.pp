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

# == Class: tripleo::haproxy::endpoint
#
# Configure a HAProxy listen endpoint
#
# [*internal_ip*]
#  The IP in which the proxy endpoint will be listening in the internal
#  network.
#
# [*service_port*]
#  The default port on which the endpoint will be listening.
#
# [*ip_addresses*]
#  The ordered list of IPs to be used to contact the balancer member.
#
# [*server_names*]
#  The names of the balancer members, which usually should be the hostname.
#
# [*member_options*]
#  Options for the balancer member, specified after the server declaration.
#  These should go in the member's configuration block.
#
# [*public_virtual_ip*]
#  Address in which the proxy endpoint will be listening in the public network.
#  If this service is internal only this should be ommited.
#  Defaults to undef.
#
# [*mode*]
#  HAProxy mode in which the endpoint will be listening. This can be undef,
#  tcp, http or health.
#  Defaults to undef.
#
# [*haproxy_listen_bind_param*]
#  A list of params to be added to the HAProxy listener bind directive.
#  Defaults to undef.
#
# [*listen_options*]
#  Options specified for the listening service's configuration block (in
#  HAproxy terms, the frontend).
#  defaults to {'option' => []}
#
# [*public_ssl_port*]
#  The port used for the public proxy endpoint if it differs from the default
#  one. This is used only if SSL is enabled, and it's used in order to avoid
#  overriding with the internal proxy endpoint (which could happen if they were
#  in the same network).
#  Defaults to undef.
#
# [*public_certificate*]
#  Certificate path used to enable TLS for the public proxy endpoint.
#  Defaults to undef.
#
# [*internal_certificate*]
#  Certificate path used to enable TLS for the internal proxy endpoint.
#  Defaults to undef.
#
define tripleo::haproxy::endpoint (
  $internal_ip,
  $service_port,
  $ip_addresses,
  $server_names,
  $member_options,
  $public_virtual_ip         = undef,
  $mode                      = undef,
  $haproxy_listen_bind_param = undef,
  $listen_options            = {
    'option' => [],
  },
  $public_ssl_port           = undef,
  $public_certificate        = undef,
  $internal_certificate      = undef,
) {
  if $public_virtual_ip {
    # service exposed to the public network

    if $public_certificate {
      $public_bind_opts = list_to_hash(suffix(any2array($public_virtual_ip), ":${public_ssl_port}"),
                                        union($haproxy_listen_bind_param, ['ssl', 'crt', $public_certificate]))
    } else {
      $public_bind_opts = list_to_hash(suffix(any2array($public_virtual_ip), ":${service_port}"), $haproxy_listen_bind_param)
    }
  } else {
    # internal service only
    $public_bind_opts = {}
  }

  if $internal_certificate {
    $internal_bind_opts = list_to_hash(suffix(any2array($internal_ip), ":${service_port}"),
                                        union($haproxy_listen_bind_param, ['ssl', 'crt', $public_certificate]))
  } else {
    $internal_bind_opts = list_to_hash(suffix(any2array($internal_ip), ":${service_port}"), $haproxy_listen_bind_param)
  }
  $bind_opts = merge($internal_bind_opts, $public_bind_opts)

  haproxy::listen { "${name}":
    bind             => $bind_opts,
    collect_exported => false,
    mode             => $mode,
    options          => $listen_options,
  }
  haproxy::balancermember { "${name}":
    listening_service => $name,
    ports             => $service_port,
    ipaddresses       => $ip_addresses,
    server_names      => $server_names,
    options           => $member_options,
  }
  if hiera('manage_firewall', true) {
    include ::tripleo::firewall
    $firewall_rules = {
      "100 ${name}_haproxy"     => {
        'dport' => $service_port,
      },
      "100 ${name}_haproxy_ssl" => {
        'dport' => $public_ssl_port,
      },
    }
    create_resources('tripleo::firewall::rule', $firewall_rules)
  }
}
