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
# == Class: tripleo::profile::base::memcached
#
# Memcached profile for tripleo
#
# === Parameters
#
# [*enable_internal_memcached_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not for
#   Memcached servers.
#   Defaults to undef
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate
#   it will create. Note that the certificate nickname must be 'memcached' in
#   the case of this service.
#   Example with hiera:
#     tripleo::profile::base::memcached::certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "memcached/<overcloud controller fqdn>"
#   Defaults to {}.
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::memcached (
  $enable_internal_memcached_tls = false,
  $certificate_specs             = {},
  $step                          = Integer(hiera('step')),
) {
  if $step >= 1 {
    if $enable_internal_memcached_tls {
      $tls_cert_chain = $certificate_specs['service_certificate']
      $tls_key = $certificate_specs['service_key']
    } else {
      $tls_cert_chain = undef
      $tls_key = undef
    }

    class { '::memcached':
      use_tls        => $enable_internal_memcached_tls,
      tls_cert_chain => $tls_cert_chain,
      tls_key        => $tls_key
    }
  }
}
