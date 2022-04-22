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
#   Defaults to lookup('cinder::backend::dellemc_unity::volume_backend_name', undef, undef, 'tripleo_dellemc_unity')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellemc_unity (
  $backend_name = lookup('cinder::backend::dellemc_unity::volume_backend_name', undef, undef, 'tripleo_dellemc_unity'),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    create_resources('cinder::backend::dellemc_unity', { $backend_name => delete_undef_values({
      'backend_availability_zone' => lookup('cinder::backend::dellemc_unity::backend_availability_zone', undef, undef, undef),
      'san_ip'                    => lookup('cinder::backend::dellemc_unity::san_ip', undef, undef, undef),
      'san_login'                 => lookup('cinder::backend::dellemc_unity::san_login', undef, undef, undef),
      'san_password'              => lookup('cinder::backend::dellemc_unity::san_password', undef, undef, undef),
      'storage_protocol'          => lookup('cinder::backend::dellemc_unity::storage_protocol', undef, undef, undef),
      'unity_io_ports'            => lookup('cinder::backend::dellemc_unity::unity_io_ports', undef, undef, undef),
      'unity_storage_pool_names'  => lookup('cinder::backend::dellemc_unity::unity_storage_pool_names', undef, undef, undef),
    })})
  }

}
