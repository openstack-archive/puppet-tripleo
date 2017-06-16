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
# == Class: tripleo::profile::base::etcd
#
# etcd profile for tripleo
#
# === Parameters
#
# [*bind_ip*]
#   (optional) IP to bind etcd service to.
#   Defaults to '127.0.0.1'.
#
# [*client_port*]
#   (optional) etcd client listening port.
#   Defaults to '2379'.
#
# [*peer_port*]
#   (optional) etcd peer listening port.
#   Defaults to '2380'.
#
# [*nodes*]
#   (Optional) Array of host(s) for etcd nodes.
#   Defaults to hiera('etcd_node_ips', []).
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate
#   it will create. Note that the certificate nickname must be 'etcd' in
#   the case of this service.
#   Example with hiera:
#     tripleo::profile::base::etcd::certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "etcd/<overcloud controller fqdn>"
#   Defaults to {}.
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::etcd (
  $bind_ip             = '127.0.0.1',
  $client_port         = '2379',
  $peer_port           = '2380',
  $nodes               = hiera('etcd_node_names', []),
  $certificate_specs   = {},
  $enable_internal_tls = hiera('enable_internal_tls', false),
  $step                = Integer(hiera('step')),
) {

  validate_hash($certificate_specs)

  if $enable_internal_tls {
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']
    $protocol = 'https'
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
    $protocol = 'http'
  }

  if $step >= 2 {
    class {'::etcd':
      listen_client_urls          => "${protocol}://${bind_ip}:${client_port}",
      advertise_client_urls       => "${protocol}://${bind_ip}:${client_port}",
      listen_peer_urls            => "${protocol}://${bind_ip}:${peer_port}",
      initial_advertise_peer_urls => "${protocol}://${bind_ip}:${peer_port}",
      initial_cluster             => regsubst($nodes, '.+', "\\0=${protocol}://\\0:${peer_port}"),
      proxy                       => 'off',
      cert_file                   => $tls_certfile,
      key_file                    => $tls_keyfile,
      client_cert_auth            => $enable_internal_tls,
      peer_cert_file              => $tls_certfile,
      peer_key_file               => $tls_keyfile,
      peer_client_cert_auth       => $enable_internal_tls,
    }
  }
}
