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
# == Class: tripleo::profile::base::cinder
#
# Cinder common profile for tripleo
#
# === Parameters
#
# [*cinder_enable_db_purge*]
#   (Optional) Wheter to enable db purging
#   Defaults to true
#
# [*pacemaker_master*]
#   (Optional) The master node runs some tasks
#   one step earlier than others; disable to
#   the node is not the master.
#   Defaults to true
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder (
  $cinder_enable_db_purge = true,
  $pacemaker_master       = true,
  $step                   = hiera('step'),
) {
  if $step >= 4 or ($step >= 3 and $pacemaker_master) {
    include ::cinder
    include ::cinder::config
  }

  if $step >= 5 {
    if $cinder_enable_db_purge {
      include ::cinder::cron::db_purge
    }
  }

}
