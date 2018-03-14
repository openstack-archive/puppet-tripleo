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
# [*member_options*]
#  Options for the balancer member, specified after the server declaration.
#  These should go in the member's configuration block.
#
# [*ip_addresses*]
#  The ordered list of IPs to be used to contact the balancer member.
#  Defaults to hiera("${name}_node_ips", undef)
#
# [*server_names*]
#  The names of the balancer members, which usually should be the hostname.
#  Defaults to hiera("${name}_node_names", undef)
#
# [*public_virtual_ip*]
#  Address in which the proxy endpoint will be listening in the public network.
#  If this service is internal only this should be ommitted.
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
# [*use_internal_certificates*]
#  Flag that indicates if we'll use an internal certificate for this specific
#  service. When set, enables SSL on the internal API endpoints using the file
#  that certmonger is tracking; this is derived from the network the service is
#  listening on.
#  Defaults to false
#
# [*internal_certificates_specs*]
#  A hash that should contain the specs that were used to create the
#  certificates. As the name indicates, only the internal certificates will be
#  fetched from here. And the keys should follow the following pattern
#  "haproxy-<network name>". The network name should be as it was defined in
#  tripleo-heat-templates.
#  Note that this is only taken into account if the $use_internal_certificates
#  flag is set.
#  Defaults to {}
#
# [*service_network*]
#  (optional) Indicates the network that the service is running on. Used for
#  fetching the certificate for that specific network.
#  Defaults to undef
#
# [*manage_firewall*]
#  (optional) Enable or disable firewall settings for ports exposed by HAProxy
#  (false means disabled, and true means enabled)
#  Defaults to hiera('tripleo::firewall::manage_firewall', true)
#
# [*authorized_userlist*]
#  (optional) Userlist that may access the endpoint. Activate Basic Authentication.
#  You'll need to create a tripleo::haproxy::userlist in order to use that option.
#  Defaults to undef
#
define tripleo::haproxy::endpoint (
  $internal_ip,
  $service_port,
  $member_options,
  $ip_addresses                = hiera("${name}_node_ips", undef),
  $server_names                = hiera("${name}_node_names", undef),
  $public_virtual_ip           = undef,
  $mode                        = undef,
  $haproxy_listen_bind_param   = undef,
  $listen_options              = {
    'option' => [],
  },
  $public_ssl_port             = undef,
  $public_certificate          = undef,
  $use_internal_certificates   = false,
  $internal_certificates_specs = {},
  $service_network             = undef,
  $manage_firewall             = hiera('tripleo::firewall::manage_firewall', true),
  $authorized_userlist         = undef,
) {
  # Let users override the options on a per-service basis
  $custom_options = hiera("tripleo::haproxy::${name}::options", undef)
  if $public_virtual_ip {
    # service exposed to the public network

    if $public_certificate {
      if $mode == 'http' {
        $tls_listen_options = {
          'rsprep'       => '^Location:\ http://(.*) Location:\ https://\1',
          'redirect'     => "scheme https code 301 if { hdr(host) -i ${public_virtual_ip} } !{ ssl_fc }",
          'option'       => 'forwardfor',
        }
        $listen_options_real = merge($tls_listen_options, $listen_options, $custom_options)
      } else {
        $listen_options_real = merge($listen_options, $custom_options)
      }
      $public_bind_opts = list_to_hash(suffix(any2array($public_virtual_ip), ":${public_ssl_port}"),
                                        union($haproxy_listen_bind_param, ['ssl', 'crt', $public_certificate]))
    } else {
      $listen_options_real = merge($listen_options, $custom_options)
      $public_bind_opts = list_to_hash(suffix(any2array($public_virtual_ip), ":${service_port}"), $haproxy_listen_bind_param)
    }
  } else {
    # internal service only
    $public_bind_opts = {}
    $listen_options_real = merge($listen_options, $custom_options)
  }

  if $use_internal_certificates {
    if !$service_network {
      fail("The service_network for this service is undefined. Can't configure TLS for the internal network.")
    }

    if $service_network == 'external' and $public_certificate {
      # NOTE(jaosorior): This service has been configured to use the external
      # network. We should use the public certificate in this case.
      $internal_cert_path = $public_certificate
    } else {
      # NOTE(jaosorior): This service is configured for the internal network.
      # We use the certificate spec hash. The key of the
      # internal_certificates_specs hash must must match the convention
      # haproxy-<network name> or else this will fail. Futherly, it must
      # contain the path that we'll use under 'service_pem'.
      $internal_cert_path = $internal_certificates_specs["haproxy-${service_network}"]['service_pem']
    }
    $internal_bind_opts = list_to_hash(suffix(any2array($internal_ip), ":${service_port}"),
                                        union($haproxy_listen_bind_param, ['ssl', 'crt', $internal_cert_path]))
  } else {
    if $service_network == 'external' and $public_certificate {
      $internal_bind_opts = list_to_hash(suffix(any2array($internal_ip), ":${service_port}"),
                                          union($haproxy_listen_bind_param, ['ssl', 'crt', $public_certificate]))
    } else {
      $internal_bind_opts = list_to_hash(suffix(any2array($internal_ip), ":${service_port}"), $haproxy_listen_bind_param)
    }
  }
  if $authorized_userlist {
    $access_rules = {
        'acl'          => "acl Auth${name} http_auth(${authorized_userlist})",
        'http-request' => "auth realm ${name} if !Auth${name}",
    }
    Haproxy::Listen[$name] {
      require => Tripleo::Haproxy::Userlist[$authorized_userlist],
    }
  } else {
    $access_rules = {}
  }

  $_real_options = merge($listen_options_real, $access_rules)

  $bind_opts = merge($internal_bind_opts, $public_bind_opts)

  haproxy::listen { "${name}":
    bind             => $bind_opts,
    collect_exported => false,
    mode             => $mode,
    options          => $_real_options,
  }
  haproxy::balancermember { "${name}":
    listening_service => $name,
    ports             => $service_port,
    ipaddresses       => $ip_addresses,
    server_names      => $server_names,
    options           => $member_options,
  }
  if $manage_firewall {
    include ::tripleo::firewall
    # This block will construct firewall rules only when we specify
    # a port for the regular service and also the ssl port for the service.
    # It makes sure we're not trying to create TCP iptables rules where no port
    # is specified.
    if $service_port {
      $haproxy_firewall_rules = {
        "100 ${name}_haproxy"     => {
          'dport' => $service_port,
        },
      }
    }
    if $public_ssl_port {
      $haproxy_ssl_firewall_rules = {
        "100 ${name}_haproxy_ssl" => {
          'dport' => $public_ssl_port,
        },
      }
    } else {
      $haproxy_ssl_firewall_rules = {}
    }
    $firewall_rules = merge($haproxy_firewall_rules, $haproxy_ssl_firewall_rules)
    if $service_port or $public_ssl_port {
      create_resources('tripleo::firewall::rule', $firewall_rules)
    }
  }
}
