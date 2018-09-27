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
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('cinder_api_short_bootstrap_node_name')
#
# [*cinder_enable_db_purge*]
#   (Optional) Wheter to enable db purging
#   Defaults to true
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*oslomsg_rpc_proto*]
#   Protocol driver for the oslo messaging rpc service
#   Defaults to hiera('messaging_rpc_service_name', rabbit)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to hiera('cinder::rabbit_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('cinder::rabbit_userid', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('cinder::rabbit_password')
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to hiera('messaging_notify_service_name', rabbit)
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to hiera('cinder::rabbit_port', 5672)
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to hiera('cinder::rabbit_userid', 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to hiera('cinder::rabbit_password')
#
# [*oslomsg_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('cinder::rabbit_use_ssl', '0')

class tripleo::profile::base::cinder (
  $bootstrap_node          = hiera('cinder_api_short_bootstrap_node_name', undef),
  $cinder_enable_db_purge  = true,
  $step                    = Integer(hiera('step')),
  $oslomsg_rpc_proto       = hiera('messaging_rpc_service_name', 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_rpc_password    = hiera('cinder::rabbit_password'),
  $oslomsg_rpc_port        = hiera('cinder::rabbit_port', '5672'),
  $oslomsg_rpc_username    = hiera('cinder::rabbit_userid', 'guest'),
  $oslomsg_notify_proto    = hiera('messaging_notify_service_name', 'rabbit'),
  $oslomsg_notify_hosts    = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_notify_password = hiera('cinder::rabbit_password'),
  $oslomsg_notify_port     = hiera('cinder::rabbit_port', '5672'),
  $oslomsg_notify_username = hiera('cinder::rabbit_userid', 'guest'),
  $oslomsg_use_ssl         = hiera('cinder::rabbit_use_ssl', '0'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    $oslomsg_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_use_ssl)))
    class { '::cinder' :
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
    }
    class { '::cinder::ceilometer' :
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
    }
    include ::cinder::config
    include ::cinder::glance
    include ::cinder::nova
  }

  if $step >= 5 {
    if $cinder_enable_db_purge {
      include ::cinder::cron::db_purge
    }
  }

}
