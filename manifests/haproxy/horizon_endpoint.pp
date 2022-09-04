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
#  If this service is internal only this should be ommitted.
#  Defaults to undef.
#
# [*use_backend_syntax*]
#  (optional) When set to true, generate a config with frontend and
#  backend sections, otherwise use listen sections.
#  Defaults to lookup('haproxy_backend_syntax', undef, undef, false)
#
# [*haproxy_listen_bind_param*]
#  A list of params to be added to the HAProxy listener bind directive.
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
# [*hsts_header_value*]
#   (optional) Adds the HTTP Strict Transport Securiy (HSTS) header to
#   response. This takes effect only when public_certificate is set.
#   Defaults to undef
#
class tripleo::haproxy::horizon_endpoint (
  $internal_ip,
  $ip_addresses,
  $server_names,
  $member_options,
  $public_virtual_ip,
  $use_backend_syntax          = lookup('haproxy_backend_syntax', undef, undef, false),
  $haproxy_listen_bind_param   = undef,
  $public_certificate          = undef,
  $use_internal_certificates   = false,
  $internal_certificates_specs = {},
  $service_network             = undef,
  $hsts_header_value           = undef,
) {
  # Let users override the options on a per-service basis
  $custom_options = lookup('tripleo::haproxy::horizon::options', undef, undef, undef)
  $custom_frontend_options = lookup('tripleo::haproxy::horizon::frontend_options', undef, undef, undef)
  $custom_backend_options = lookup('tripleo::haproxy::horizon::backend_options', undef, undef, undef)
  $custom_bind_options_public = delete(
    any2array(lookup('tripleo::haproxy::horizon::public_bind_options', undef, undef, undef)),
    undef).flatten()
  $custom_bind_options_internal = delete(
    any2array(lookup('tripleo::haproxy::horizon::internal_bind_options', undef, undef, undef)),
    undef).flatten()

  # service exposed to the public network
  if $public_certificate {
    if $use_internal_certificates {
      if !$service_network {
        fail("The service_network for this service is undefined. Can't configure TLS for the internal network.")
      }
      # NOTE(jaosorior): The key of the internal_certificates_specs hash must
      # must match the convention haproxy-<network name> or else this
      # will fail. Futherly, it must contain the path that we'll use under
      # 'service_pem'.
      $internal_cert_path = $internal_certificates_specs["haproxy-${service_network}"]['service_pem']
      $internal_bind_opts = union($haproxy_listen_bind_param, ['ssl', 'crt', $internal_cert_path])
    } else {
      # If no internal cert is given, we still configure TLS for the internal
      # network, however, we expect that the public certificate has appropriate
      # subjectaltnames set.
      $internal_bind_opts = union($haproxy_listen_bind_param, ['ssl', 'crt', $public_certificate])
    }
    # NOTE(jaosorior): If the internal_ip and the public_virtual_ip are the
    # same, the first option takes precedence. Which is the case when network
    # isolation is not enabled. This is not a problem as both options are
    # identical. If network isolation is enabled, this works correctly and
    # will add a TLS binding to both the internal_ip and the
    # public_virtual_ip.
    # Even though for the public_virtual_ip the port 80 is listening, we
    # redirect to https in the horizon_options below.
    $horizon_bind_opts = {
      "${internal_ip}:80"        => union($haproxy_listen_bind_param, $custom_bind_options_internal),
      "${internal_ip}:443"       => union($internal_bind_opts, $custom_bind_options_internal),
      "${public_virtual_ip}:80"  => union($haproxy_listen_bind_param, $custom_bind_options_public),
      "${public_virtual_ip}:443" => union($haproxy_listen_bind_param, ['ssl', 'crt', $public_certificate], $custom_bind_options_public),
    }

    if $hsts_header_value != undef {
      $hsts_header_value_real = join(any2array($hsts_header_value), '; ')
      $hsts_response = "set-header Strict-Transport-Security \"${hsts_header_value_real};\""
    } else {
      $hsts_response = undef
    }

    $horizon_frontend_options = {
      'http-response' => delete_undef_values([
          'replace-header Location http://(.*) https://\\1',
          $hsts_response]),
      # NOTE(jaosorior): We always redirect to https for the public_virtual_ip.
      'redirect'      => 'scheme https code 301 if !{ ssl_fc }',
      'option'        => [ 'forwardfor' ],
      'http-request'  => [
          'set-header X-Forwarded-Proto https if { ssl_fc }',
          'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
    }
  } else {
    $horizon_bind_opts = {
      "${internal_ip}:80" => union($haproxy_listen_bind_param, $custom_bind_options_internal),
      "${public_virtual_ip}:80" => union($haproxy_listen_bind_param, $custom_bind_options_public),
    }
    $horizon_frontend_options = {
      'option' => [ 'forwardfor' ],
    }
  }
  $horizon_backend_options = {
    'cookie' => 'SERVERID insert indirect nocache',
    'option' => [ 'httpchk' ],
  }
  $horizon_options = merge_hash_values($horizon_backend_options,
                                          $horizon_frontend_options)

  if $use_internal_certificates {
    # Use SSL port if TLS in the internal network is enabled.
    $backend_port = '443'
  } else {
    $backend_port = '80'
  }

  if $use_backend_syntax {
    haproxy::frontend { 'horizon':
      bind             => $horizon_bind_opts,
      options          => merge($horizon_frontend_options,
                                  { default_backend => 'horizon_be' },
                                  $custom_frontend_options),
      mode             => 'http',
      collect_exported => false,
    }
    haproxy::backend { 'horizon_be':
      options => merge($horizon_backend_options, $custom_backend_options),
      mode    => 'http',
    }
  } else {
    haproxy::listen { 'horizon':
      bind             => $horizon_bind_opts,
      options          => merge($horizon_options, $custom_options),
      mode             => 'http',
      collect_exported => false,
    }
  }
  hash(zip($ip_addresses, $server_names)).each | $ip, $server | {
    # We need to be sure the IP (IPv6) don't have colons
    # which is a reserved character to reference manifests
    $non_colon_ip = regsubst($ip, ':', '-', 'G')
    haproxy::balancermember { "horizon_${non_colon_ip}_${server}":
      listening_service => 'horizon_be',
      ports             => $backend_port,
      ipaddresses       => $ip,
      server_names      => $server,
      options           => union($member_options, ["cookie ${server}"]),
    }
  }
}
