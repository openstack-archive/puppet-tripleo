# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::designate::worker
#
# Designate Worker profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rndc_key*]
#   (Optional) The base64-encoded key secret for /etc/rndc.key.
#   Defaults to hiera('designate_rndc_key')
#
class tripleo::profile::base::designate::worker (
  $step = Integer(hiera('step')),
  $rndc_key = hiera('designate_rndc_key', false),
) {
  include tripleo::profile::base::designate

  if $step >= 4 {
    if $rndc_key {
      file { 'designate rndc key':
        path    => '/etc/rndc.key',
        content => template('tripleo/designate/rndc.key.erb')
      }
    }
    include designate::worker
  }
}
