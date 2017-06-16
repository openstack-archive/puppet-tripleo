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
# == Class: tripleo::profile::base::neutron::opencontrail::vrouter
#
# Opencontrail profile to run the contrail vrouter
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::opencontrail::vrouter (
  $step                      = Integer(hiera('step')),
) {

  if $step >= 4 {

    include ::contrail::vrouter
    # NOTE: it's not possible to use this class without a functional
    # contrail controller up and running
    #class {'::contrail::vrouter::provision_vrouter':
    #  require => Class['contrail::vrouter'],
    #}

  }

}
