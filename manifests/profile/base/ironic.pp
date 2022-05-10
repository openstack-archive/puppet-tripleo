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
# == Class: tripleo::profile::base::ironic
#
# Ironic profile for TripleO
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('ironic_api_short_bootstrap_node_name', undef, undef, undef)
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to Integer(lookup('step'))
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit')
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef))
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_port', undef, undef, '5672')
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to lookup('oslo_messaging_rpc_password')
#
# [*oslomsg_rpc_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0')

class tripleo::profile::base::ironic (
  $bootstrap_node       = lookup('ironic_api_short_bootstrap_node_name', undef, undef, undef),
  $step                 = Integer(lookup('step')),
  $oslomsg_rpc_proto    = lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit'),
  $oslomsg_rpc_hosts    = any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef)),
  $oslomsg_rpc_password = lookup('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port     = lookup('oslo_messaging_rpc_port', undef, undef, '5672'),
  $oslomsg_rpc_username = lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest'),
  $oslomsg_rpc_use_ssl  = lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0'),
) {
  # Database is accessed by both API and conductor, hence it's here.
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    class { 'ironic':
      sync_db                   => $sync_db,
      db_online_data_migrations => $sync_db,
      default_transport_url     => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => sprintf('%s', $oslomsg_rpc_port),
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_rpc_use_ssl_real,
      }),
    }

    include ironic::config
    include ironic::json_rpc
    include ironic::cors
    include ironic::db
    include ironic::logging
  }
}
