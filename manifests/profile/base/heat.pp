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
# [*messaging_driver*]
#   Driver for messaging service.
#   Defaults to hiera('messaging_service_name', 'rabbit')
#
# [*messaging_hosts*]
#   list of the messaging host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*messaging_password*]
#   Password for messaging heat queue
#   Defaults to hiera('heat::rabbit_password')
#
# [*messaging_port*]
#   IP port for messaging service
#   Defaults to hiera('heat::rabbit_port', 5672)
#
# [*messaging_username*]
#   Username for messaging heat queue
#   Defaults to hiera('heat::rabbit_userid', 'guest')
#
# [*messaging_use_ssl*]
#   Flag indicating ssl usage.
#   Defaults to hiera('heat::rabbit_use_ssl', '0')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#

class tripleo::profile::base::heat (
  $bootstrap_node      = downcase(hiera('bootstrap_nodeid')),
  $manage_db_purge     = hiera('heat_enable_db_purge', true),
  $messaging_driver    = hiera('messaging_service_name', 'rabbit'),
  $messaging_hosts     = any2array(hiera('rabbitmq_node_names', undef)),
  $messaging_password  = hiera('heat::rabbit_password'),
  $messaging_port      = hiera('heat::rabbit_port', '5672'),
  $messaging_username  = hiera('heat::rabbit_userid', 'guest'),
  $messaging_use_ssl   = hiera('heat::rabbit_use_ssl', '0'),
  $step                = hiera('step'),
) {
  # Domain resources will be created at step5 on the node running keystone.pp
  # configure heat.conf at step3 and 4 but actually create the domain later.
  if $step >= 3 {
    class { '::heat::keystone::domain':
      manage_domain => false,
      manage_user   => false,
      manage_role   => false,
    }

    $messaging_use_ssl_real = sprintf('%s', bool2num(str2bool($messaging_use_ssl)))

    # TODO(ccamacho): remove sprintf once we properly type the port, needs
    # to be a string for the os_transport_url function.
    class { '::heat' :
      default_transport_url => os_transport_url({
        'transport' => $messaging_driver,
        'hosts'     => $messaging_hosts,
        'password'  => $messaging_password,
        'port'      => sprintf('%s', $messaging_port),
        'username'  => $messaging_username,
        'ssl'       => $messaging_use_ssl_real,
      }),
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

