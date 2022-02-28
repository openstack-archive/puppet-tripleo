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
# == Class: tripleo::profile::base::designate::producer
#
# Designate Producer profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::designate::producer (
  $step = Integer(hiera('step')),
) {
  include tripleo::profile::base::designate
  include tripleo::profile::base::designate::coordination

  if $step >= 4 {
    include designate::producer
    include designate::producer_task::delayed_notify
    include designate::producer_task::periodic_exists
    include designate::producer_task::periodic_secondary_refresh
    include designate::producer_task::worker_periodic_recovery
    include designate::producer_task::zone_purge
  }
}
