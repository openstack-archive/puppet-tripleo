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
# == Class: tripleo::profile::base::neutron::opendaylight
#
# OpenDaylight Neutron profile for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*primary_node*]
#   (Optional) The hostname of the first node of this role type
#   Defaults to hiera('bootstrap_nodeid', undef)
#
class tripleo::profile::base::neutron::opendaylight (
  $step         = hiera('step'),
  $primary_node = hiera('bootstrap_nodeid', undef),
) {

  if $step >= 1 {
    # Configure ODL only on first node of the role where this service is
    # applied
    if $primary_node == downcase($::hostname) {
      include ::opendaylight
    }
  }
}
