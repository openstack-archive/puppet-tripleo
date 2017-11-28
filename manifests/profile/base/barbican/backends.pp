# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::barbican::backends
#
# Barbican's secret store plugin profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*simple_crypto_backend_enabled*]
#   (Optional) Whether the simple crypto backend is enabled or not. This is
#   dynamically set via t-h-t.
#   Defaults to hiera('barbican_backend_simple_crypto_enabled', false)
#
# [*dogtag_backend_enabled*]
#   (Optional) Whether the Dogtag backend is enabled or not. This is
#   dynamically set via t-h-t.
#   Defaults to hiera('barbican_backend_dogtag_enabled', false)
#
# [*p11_crypto_backend_enabled*]
#   (Optional) Whether the pkcs11 crypto backend is enabled or not. This is
#   dynamically set via t-h-t.
#   Defaults to hiera('barbican_backend_pkcs11_crypto_enabled', false)
#
# [*kmip_backend_enabled*]
#   (Optional) Whether the KMIP backend is enabled or not. This is
#   dynamically set via t-h-t.
#   Defaults to hiera('barbican_backend_kmip_enabled', false)
#
class tripleo::profile::base::barbican::backends (
  $simple_crypto_backend_enabled = hiera('barbican_backend_simple_crypto_enabled', false),
  $dogtag_backend_enabled        = hiera('barbican_backend_dogtag_enabled', false),
  $p11_crypto_backend_enabled    = hiera('barbican_backend_pkcs11_crypto_enabled', false),
  $kmip_backend_enabled          = hiera('barbican_backend_kmip_enabled', false),
) {
  if $simple_crypto_backend_enabled {
    include ::barbican::plugins::simple_crypto
    $backend1 = 'simple_crypto'
  } else {
    $backend1 = undef
  }

  if $dogtag_backend_enabled {
    include ::barbican::plugins::dogtag
    $backend2 = 'dogtag'
  } else {
    $backend2 = undef
  }

  if $p11_crypto_backend_enabled {
    include ::barbican::plugins::p11_crypto
    $backend3 = 'pkcs11'
  } else {
    $backend3 = undef
  }

  if $kmip_backend_enabled {
    include ::barbican::plugins::kmip
    $backend4 = 'kmip'
  } else {
    $backend4 = undef
  }

  $enabled_backends_list = [$backend1, $backend2, $backend3, $backend4].filter |$items| { $items != undef }
  $enabled_secret_stores = join($enabled_backends_list, ',')
}
