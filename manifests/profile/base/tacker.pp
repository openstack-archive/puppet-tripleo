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
# == Class: tripleo::profile::base::tacker
#
# Tacker server profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*rabbit_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('rabbitmq_node_names', undef)
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to hiera('messaging_rpc_service_name', rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('oslo_messaging_rpc_node_names', undef)
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to hiera('tacker::rabbit_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('tacker::rabbit_userid', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('tacker::rabbit_password')
#
# [*oslomsg_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('tacker::rabbit_use_ssl', '0')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')

class tripleo::profile::base::tacker (
  $bootstrap_node       = hiera('bootstrap_nodeid', undef),
  $rabbit_hosts         = hiera('rabbitmq_node_names', undef),
  $oslomsg_rpc_proto    = hiera('messaging_rpc_service_name', 'rabbit'),
  $oslomsg_rpc_hosts    = hiera('oslo_messaging_rpc_node_names', undef),
  $oslomsg_rpc_password = hiera('tacker::rabbit_password'),
  $oslomsg_rpc_port     = hiera('tacker::rabbit_port', '5672'),
  $oslomsg_rpc_username = hiera('tacker::rabbit_userid', 'guest'),
  $oslomsg_use_ssl      = hiera('tacker::rabbit_use_ssl', '0'),
  $step                 = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db){
    $oslomsg_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_use_ssl)))
    $oslomsg_rpc_hosts_real = any2array(pick($rabbit_hosts, $oslomsg_rpc_hosts, []))
    class { '::tacker':
      sync_db               => $sync_db,
      default_transport_url => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts_real,
        'port'      => sprintf('%s', $oslomsg_rpc_port),
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
    }

    include ::tacker::server
    include ::tacker::db
  }
}
