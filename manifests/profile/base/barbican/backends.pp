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
# Barbican's simple crypto plugin profile for tripleo
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
class tripleo::profile::base::barbican::backends (
  $simple_crypto_backend_enabled = hiera('barbican_backend_simple_crypto_enabled', false)
) {
  if $simple_crypto_backend_enabled {
    include ::barbican::plugins::simple_crypto
    # Note that once we start adding more backends, this will be refactored to
    # create a proper lits from all the enabled plugins.
    $enabled_secretstore_plugins = 'store_crypto'
    $enabled_crypto_plugins = 'simple_crypto'
  } else {
    $enabled_secretstore_plugins = ''
    $enabled_crypto_plugins = ''
  }
}
