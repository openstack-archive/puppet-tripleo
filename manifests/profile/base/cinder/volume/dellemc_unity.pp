# Copyright (c) 2016-2017 Dell Inc, or its subsidiaries.
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
# == Class: tripleo::profile::base::cinder::volume::dellemc_unity
#
# Cinder Volume dellemc_unity profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_dellemc_unity'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::dellemc_unity (
  $backend_name = hiera('cinder::backend::dellemc_unity::volume_backend_name', 'tripleo_dellemc_unity'),
  $step         = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::dellemc_unity { $backend_name :
      san_ip                   => hiera('cinder::backend::dellemc_unity::san_ip', undef),
      san_login                => hiera('cinder::backend::dellemc_unity::san_login', undef),
      san_password             => hiera('cinder::backend::dellemc_unity::san_password', undef),
      storage_protocol         => hiera('cinder::backend::dellemc_unity::storage_protocol', undef),
      unity_io_ports           => hiera('cinder::backend::dellemc_unity::unity_io_ports', undef),
      unity_storage_pool_names => hiera('cinder::backend::dellemc_unity::unity_storage_pool_names', undef),
    }
  }

}
