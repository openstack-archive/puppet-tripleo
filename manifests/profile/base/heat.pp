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
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to downcase(hiera('bootstrap_nodeid'))
#
# [*manage_db_purge*]
#   (Optional) Whether keystone token flushing should be enabled
#   Defaults to hiera('keystone_enable_db_purge', true)
#
# [*notification_driver*]
#   (Optional) Heat notification driver to use.
#   Defaults to 'messaging'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')

class tripleo::profile::base::heat (
  $bootstrap_node      = downcase(hiera('bootstrap_nodeid')),
  $manage_db_purge     = hiera('heat_enable_db_purge', true),
  $notification_driver = 'messaging',
  $step                = hiera('step'),
  $rabbit_hosts        = hiera('rabbitmq_node_ips', undef),
) {
  # Domain resources will be created at step5 on the bootstrap_node so we
  # configure heat.conf at step3 and 4 but actually create the domain later.
  if $step == 3 or $step == 4 {
    class { '::heat::keystone::domain':
      manage_domain => false,
      manage_user   => false,
      manage_role   => false,
    }
  }

  if $step >= 4 {
    class { '::heat' :
      notification_driver => $notification_driver,
      rabbit_hosts        => $rabbit_hosts,
    }
    include ::heat::config
    include ::heat::cors
  }

  if $step >= 5 {
    if $manage_db_purge {
      include ::heat::cron::purge_deleted
    }
    if $bootstrap_node == $::hostname {
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

