# Copyright 2018 Red Hat, Inc.
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
# == Class:tripleo::profile::base::neutron::plugins::ml2::networking_baremetal
#
# Neutron networking-baremetal ML2 plugin profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#

class tripleo::profile::base::neutron::plugins::ml2::networking_baremetal(
  $step               = Integer(hiera('step'))
) {

  include ::tripleo::profile::base::neutron

  if $step >= 4 {
    include ::neutron::plugins::ml2::networking_baremetal
  }
}
