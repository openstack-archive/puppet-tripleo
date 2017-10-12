# Copyright 2017 Nuage Networks from Nokia Inc.
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
# == Class: tripleo::profile::base::neutron::plugins::ml2::nuage
#
# Nuage Neutron ML2 profile for tripleo
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*mechanism_drivers*]
#   (Optional) The mechanism drivers to use with the Ml2 plugin
#   Defaults to hiera('neutron::plugins::ml2::mechanism_drivers')
#
class tripleo::profile::base::neutron::plugins::ml2::nuage (
  $step              = hiera('step'),
  $mechanism_drivers = hiera('neutron::plugins::ml2::mechanism_drivers'),
) {

  if $step >= 4 {
    include ::neutron::plugins::ml2::nuage

    if 'sriovnicswitch' in $mechanism_drivers {
      include ::nova::patch::config
    }
  }
}
