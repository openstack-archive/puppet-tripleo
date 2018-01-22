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
# == Class: tripleo::profile::base::neutron::opendaylight
#
# OpenDaylight Neutron profile for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*odl_api_ips*]
#   (Optional) List of OpenStack Controller IPs for ODL API
#   Defaults to hiera('opendaylight_api_node_ips')
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
class tripleo::profile::base::neutron::opendaylight (
  $step                = Integer(hiera('step')),
  $odl_api_ips         = hiera('opendaylight_api_node_ips'),
  $certificate_specs   = {},
  $enable_internal_tls = hiera('enable_internal_tls', false),
) {

  validate_hash($certificate_specs)

  if $enable_internal_tls {
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 1 {
    validate_array($odl_api_ips)
    if empty($odl_api_ips) {
      fail('No IPs assigned to OpenDaylight Api Service')
    } elsif size($odl_api_ips) == 2 {
      fail('2 node OpenDaylight deployments are unsupported.  Use 1 or greater than 2')
    } elsif size($odl_api_ips) > 2 {
      class { '::opendaylight':
        enable_ha     => true,
        ha_node_ips   => $odl_api_ips,
        enable_tls    => $enable_internal_tls,
        tls_key_file  => $tls_keyfile,
        tls_cert_file => $tls_certfile
      }
    } else {
      class { '::opendaylight':
        enable_tls    => $enable_internal_tls,
        tls_key_file  => $tls_keyfile,
        tls_cert_file => $tls_certfile
      }
    }
  }
}
