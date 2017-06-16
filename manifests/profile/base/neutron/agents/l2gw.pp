#
# Copyright (C) 2017 Red Hat Inc.
#
# Author: Peng Liu <pliu@redhat.com>
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
# == Class: tripleo::profile::base::neutron::agent::l2gw
#
# Neutron L2 Gateway agent profile for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::agents::l2gw (
  $step = Integer(hiera('step')),
) {
  if $step >= 4 {
    include ::neutron::agents::l2gw
  }
}
