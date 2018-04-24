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
# == Class: tripleo::profile::base::neutron::lbaas
#
# Neutron LBaaS Agent profile for TripleO
#
# === Parameters
#
# [*manage_haproxy_package*]
#   (Optional) Whether to manage the haproxy package.
#   Defaults to hiera('manage_haproxy_package', false)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::agents::lbaas(
  $manage_haproxy_package = hiera('manage_haproxy_package', false),
  $step                   = Integer(hiera('step')),
) {

  #LBaaS Driver needs to be run @ $step>=5 as the neutron service needs to already be active which is run @ $step==4
  if $step >= 5 {
    class {'::neutron::agents::lbaas':
      manage_haproxy_package => $manage_haproxy_package
    }
  }
}
