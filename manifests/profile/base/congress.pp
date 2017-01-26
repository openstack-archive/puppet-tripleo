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
# == Class: tripleo::profile::base::congress
#
# Congress server profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
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
#   Password for messaging congress queue
#   Defaults to hiera('congress::rabbit_password')
#
# [*messaging_port*]
#   IP port for messaging service
#   Defaults to hiera('congress::rabbit_port', 5672)
#
# [*messaging_username*]
#   Username for messaging congress queue
#   Defaults to hiera('congress::rabbit_userid', 'guest')
#
# [*messaging_use_ssl*]
#   Flag indicating ssl usage.
#   Defaults to hiera('congress::rabbit_use_ssl', '0')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')

class tripleo::profile::base::congress (
  $bootstrap_node       = hiera('bootstrap_nodeid', undef),
  $messaging_driver     = hiera('messaging_service_name', 'rabbit'),
  $messaging_hosts      = any2array(hiera('rabbitmq_node_names', undef)),
  $messaging_password   = hiera('congress::rabbit_password'),
  $messaging_port       = hiera('congress::rabbit_port', '5672'),
  $messaging_username   = hiera('congress::rabbit_userid', 'guest'),
  $messaging_use_ssl    = hiera('congress::rabbit_use_ssl', '0'),
  $step                 = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db){
    $messaging_use_ssl_real = sprintf('%s', bool2num(str2bool($messaging_use_ssl)))
    class { '::congress':
      sync_db               => $sync_db,
      default_transport_url => os_transport_url({
        'transport' => $messaging_driver,
        'hosts'     => $messaging_hosts,
        'port'      => sprintf('%s', $messaging_port),
        'username'  => $messaging_username,
        'password'  => $messaging_password,
        'ssl'       => $messaging_use_ssl_real,
      }),
    }

    include ::congress::server
    include ::congress::db
  }
}
