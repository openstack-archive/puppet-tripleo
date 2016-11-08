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
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('heat::rabbit_port', 5672)

class tripleo::profile::base::heat (
  $bootstrap_node      = downcase(hiera('bootstrap_nodeid')),
  $manage_db_purge     = hiera('heat_enable_db_purge', true),
  $notification_driver = 'messaging',
  $step                = hiera('step'),
  $rabbit_hosts        = hiera('rabbitmq_node_ips', undef),
  $rabbit_port         = hiera('heat::rabbit_port', 5672),
) {
  # Domain resources will be created at step5 on the node running keystone.pp
  # configure heat.conf at step3 and 4 but actually create the domain later.
  if $step >= 3 {
    class { '::heat::keystone::domain':
      manage_domain => false,
      manage_user   => false,
      manage_role   => false,
    }
  }

  if $step >= 4 {
    $rabbit_endpoints = suffix(any2array(normalize_ip_for_uri($rabbit_hosts)), ":${rabbit_port}")
    class { '::heat' :
      notification_driver => $notification_driver,
      rabbit_hosts        => $rabbit_endpoints,
    }
    include ::heat::config
    include ::heat::cors
  }

  if $step >= 5 {
    if $manage_db_purge {
      include ::heat::cron::purge_deleted
    }
  }
}

