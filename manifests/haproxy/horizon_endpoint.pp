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
class tripleo::haproxy::horizon_endpoint (
  $internal_ip,
  $ip_addresses,
  $server_names,
  $member_options,
  $public_virtual_ip,
  $haproxy_listen_bind_param   = undef,
  $public_certificate          = undef,
  $use_internal_certificates   = false,
  $internal_certificates_specs = {},
  $service_network             = undef,
) {
  # Let users override the options on a per-service basis
  $custom_options = hiera('tripleo::haproxy::horizon::options', undef)
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
      "${internal_ip}:80"        => $haproxy_listen_bind_param,
      "${internal_ip}:443"       => $internal_bind_opts,
      "${public_virtual_ip}:80"  => $haproxy_listen_bind_param,
      "${public_virtual_ip}:443" => union($haproxy_listen_bind_param, ['ssl', 'crt', $public_certificate]),
    }
    $horizon_options = merge({
      'cookie'       => 'SERVERID insert indirect nocache',
      'rsprep'       => '^Location:\ http://(.*) Location:\ https://\1',
      # NOTE(jaosorior): We always redirect to https for the public_virtual_ip.
      'redirect'     => 'scheme https code 301 if !{ ssl_fc }',
      'option'       => [ 'forwardfor', 'httpchk' ],
      'http-request' => [
          'set-header X-Forwarded-Proto https if { ssl_fc }',
          'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
    }, $custom_options)
  } else {
    $horizon_bind_opts = {
      "${internal_ip}:80" => $haproxy_listen_bind_param,
      "${public_virtual_ip}:80" => $haproxy_listen_bind_param,
    }
    $horizon_options = merge({
      'cookie' => 'SERVERID insert indirect nocache',
      'option' => [ 'forwardfor', 'httpchk' ],
    }, $custom_options)
  }

  if $use_internal_certificates {
    # Use SSL port if TLS in the internal network is enabled.
    $backend_port = '443'
  } else {
    $backend_port = '80'
  }

  haproxy::listen { 'horizon':
    bind             => $horizon_bind_opts,
    options          => $horizon_options,
    mode             => 'http',
    collect_exported => false,
  }
  hash(zip($ip_addresses, $server_names)).each | $ip, $server | {
    # We need to be sure the IP (IPv6) don't have colons
    # which is a reserved character to reference manifests
    $non_colon_ip = regsubst($ip, ':', '-', 'G')
    haproxy::balancermember { "horizon_${non_colon_ip}_${server}":
      listening_service => 'horizon',
      ports             => $backend_port,
      ipaddresses       => $ip,
      server_names      => $server,
      options           => union($member_options, ["cookie ${server}"]),
    }
  }
}
