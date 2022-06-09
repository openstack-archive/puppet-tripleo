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
# == Class: tripleo::profile::base::nova::migration
#
# Nova migration profile for tripleo, common to both client and target.
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to Integer(lookup('step'))
#

class tripleo::profile::base::nova::migration (
  $step = Integer(lookup('step')),
) {
  if $step >= 3 {
    package { 'openstack-nova-migration':
      ensure => present,
      tag    => ['openstack', 'nova-package'],
    }
  }
}
