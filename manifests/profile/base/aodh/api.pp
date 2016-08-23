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
# == Class: tripleo::profile::base::aodh::api
#
# aodh API profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*enable_combination_alarms*]
#   (optional) Setting to enable combination alarms
#   Defaults to: false
#

class tripleo::profile::base::aodh::api (
  $step                      = hiera('step'),
  $enable_combination_alarms = false,
) {

  include ::tripleo::profile::base::aodh

  if $step >= 4 {
    include ::aodh::api
    include ::aodh::wsgi::apache

    #NOTE: Combination alarms are deprecated in newton and disabled by default.
    # we need a way to override this setting for users still using this type
    # of alarms.
    aodh_config {
      'api/enable_combination_alarms' : value => $enable_combination_alarms;
    }
  }
}
