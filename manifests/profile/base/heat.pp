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
# == Class: tripleo::profile::base::heat
#
# Heat profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*notification_driver*]
#   (Optional) Heat notification driver to use.
#   Defaults to 'messaging'
#
# [*bootstrap_master*]
#   (Optional) The hostname of the node responsible for bootstrapping
#   Defaults to downcase(hiera('bootstrap_nodeid'))
#
# [*manage_db_purge*]
#   (Optional) Whether keystone token flushing should be enabled
#   Defaults to hiera('keystone_enable_db_purge', true)
#
class tripleo::profile::base::heat (
  $step = hiera('step'),
  $notification_driver = 'messaging',
  $bootstrap_master = downcase(hiera('bootstrap_nodeid')),
  $manage_db_purge = hiera('heat_enable_db_purge', true),
) {

  if $step >= 4 {
    class { '::heat' :
      notification_driver => $notification_driver,
    }
    include ::heat::config
  }

  if $step >= 5 {
    if $manage_db_purge {
      include ::heat::cron::purge_deleted
    }
    if $bootstrap_master == $::hostname {
      # Class ::heat::keystone::domain has to run on bootstrap node
      # because it creates DB entities via API calls.
      include ::heat::keystone::domain

      Class['::keystone::roles::admin'] -> Class['::heat::keystone::domain']
    } else {
      # On non-bootstrap node we don't need to create Keystone resources again
      class { '::heat::keystone::domain':
        manage_domain => false,
        manage_user   => false,
        manage_role   => false,
      }
    }
  }
}

