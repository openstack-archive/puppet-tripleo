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
# == Class: tripleo::profile::base::neutron::plumgrid
#
# Plumgrid Neutron helper profile (extra settings for compute, etc. roles)
#
# === Parameters
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plumgrid (
  $step                      = Integer(hiera('step')),
) {

  if $step >= 4 {

    # ifc_ctl_pp needs to be invoked by root as part of the vif.py when a VM is powered on
    file { '/etc/sudoers.d/ifc_ctl_sudoers':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0440',
      content => "nova ALL=(root) NOPASSWD: /opt/pg/bin/ifc_ctl_pp *\n",
    }

  }

}
