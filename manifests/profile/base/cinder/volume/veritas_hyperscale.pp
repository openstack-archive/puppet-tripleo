# Copyright (c) 2017 Veritas Technologies LLC.
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
# == Class: tripleo::profile::base::cinder::volume::veritas_hyperscale
#
# Cinder Volume Veritas HyperScale profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) The name of Veritas HyperScale cinder backend.
#   Currently the backend name is hard-coded in the driver, and it won't
#   function if other value is set in hiera.
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::veritas_hyperscale (
  # Note: Currently the backend name is hard-coded in the driver, and it won't
  # function if other value is set in hiera.
  $backend_name = hiera('cinder::backend::veritas_hyperscale::volume_backend_name', 'Veritas_HyperScale'),
  $step = Integer(hiera('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::veritas_hyperscale { $backend_name :
      backend_availability_zone => hiera('cinder::backend::veritas_hyperscale::backend_availability_zone', undef)
    }
  }

}
