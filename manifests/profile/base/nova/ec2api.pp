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
# == Class: tripleo::profile::base::nova::ec2api
#
# EC2-compatible Nova API profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Example with hiera:
#     apache_certificates_specs:
#       httpd-internal_api:
#         hostname: <overcloud controller fqdn>
#         service_certificate: <service certificate path>
#         service_key: <service key path>
#         principal: "haproxy/<overcloud controller fqdn>"
#   Defaults to hiera('apache_certificate_specs', {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*ec2_api_network*]
#   (Optional) The network name where the ec2api endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('ec2_api_network', undef)
#
# [*ec2_api_metadata_network*]
#   (Optional) The network name where the ec2api metadata endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('ec2_api_network', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*ec2_api_tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only used if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*ec2_api_tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. Required only used if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*ec2_api_tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   Defaults to 8788
#
# [*metadata_tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only used if
#   enable_internal_tls is set.
#   Defaults to undef
#
#  [*metadata_tls_proxy_fqdn*]
#    fqdn on which the tls proxy will listen on. Required only used if
#    enable_internal_tls is set.
#    Defaults to undef
#
#  [*metadata_tls_proxy_port*]
#    port on which the tls proxy will listen on. Only used if
#    enable_internal_tls is set.
#    Defaults to 8789
#
class tripleo::profile::base::nova::ec2api (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $ec2_api_network               = hiera('ec2_api_network', undef),
  $ec2_api_metadata_network      = hiera('ec2_api_network', undef),
  $step                          = Integer(hiera('step')),
  $ec2_api_tls_proxy_bind_ip     = undef,
  $ec2_api_tls_proxy_fqdn        = undef,
  $ec2_api_tls_proxy_port        = 8788,
  $metadata_tls_proxy_bind_ip    = undef,
  $metadata_tls_proxy_fqdn       = undef,
  $metadata_tls_proxy_port       = 8789,
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $enable_internal_tls {
      if !$ec2_api_network {
        fail('ec2_api_network is not set in the hieradata.')
      }
      $ec2_api_tls_certfile = $certificates_specs["httpd-${ec2_api_network}"]['service_certificate']
      $ec2_api_tls_keyfile = $certificates_specs["httpd-${ec2_api_network}"]['service_key']

      ::tripleo::tls_proxy { 'ec2-api':
        servername    => $ec2_api_tls_proxy_fqdn,
        ip            => $ec2_api_tls_proxy_bind_ip,
        port          => $ec2_api_tls_proxy_port,
        tls_cert      => $ec2_api_tls_certfile,
        tls_key       => $ec2_api_tls_keyfile,
        preserve_host => true,
      }
      Tripleo::Tls_proxy['ec2-api'] ~> Anchor<| title == 'ec2api::service::begin' |>

      if !$ec2_api_metadata_network {
        fail('ec2_api_metadata_network is not set in the hieradata.')
      }
      $metadata_tls_certfile = $certificates_specs["httpd-${ec2_api_metadata_network}"]['service_certificate']
      $metadata_tls_keyfile = $certificates_specs["httpd-${ec2_api_metadata_network}"]['service_key']

      ::tripleo::tls_proxy { 'ec2-api-metadata':
        servername => $metadata_tls_proxy_fqdn,
        ip         => $metadata_tls_proxy_bind_ip,
        port       => $metadata_tls_proxy_port,
        tls_cert   => $metadata_tls_certfile,
        tls_key    => $metadata_tls_keyfile,
      }
      Tripleo::Tls_proxy['ec2-api-metadata'] ~> Anchor<| title == 'ec2api::service::begin' |>
    }
    include ::ec2api
    include ::ec2api::api
    include ::ec2api::db::sync
    include ::ec2api::metadata
    include ::ec2api::keystone::authtoken
  }
}
