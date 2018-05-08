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
# [*enable_vrs*]
#   (Optional) Enable VRS or not
#   Defaults to false
#
class tripleo::profile::base::neutron::plugins::ml2::nuage (
  $step              = hiera('step'),
  $enable_vrs        = false,
) {

  if $step >= 4 {
    include ::neutron::plugins::ml2::nuage

    if $enable_vrs {
      include ::nuage::vrs
    }
  }
}
