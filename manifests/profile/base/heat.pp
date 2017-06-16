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
#   Defaults to hiera('heat::rabbit_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('heat::rabbit_userid', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('heat::rabbit_password')
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
#   Defaults to hiera('heat::rabbit_port', 5672)
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to hiera('heat::rabbit_userid', 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to hiera('heat::rabbit_password')
#
# [*oslomsg_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('heat::rabbit_use_ssl', '0')

class tripleo::profile::base::heat (
  $bootstrap_node          = downcase(hiera('bootstrap_nodeid')),
  $manage_db_purge         = hiera('heat_enable_db_purge', true),
  $notification_driver     = 'messaging',
  $step                    = Integer(hiera('step')),
  $oslomsg_rpc_proto       = hiera('messaging_rpc_service_name', 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_rpc_password    = hiera('heat::rabbit_password'),
  $oslomsg_rpc_port        = hiera('heat::rabbit_port', '5672'),
  $oslomsg_rpc_username    = hiera('heat::rabbit_userid', 'guest'),
  $oslomsg_notify_proto    = hiera('messaging_notify_service_name', 'rabbit'),
  $oslomsg_notify_hosts    = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_notify_password = hiera('heat::rabbit_password'),
  $oslomsg_notify_port     = hiera('heat::rabbit_port', '5672'),
  $oslomsg_notify_username = hiera('heat::rabbit_userid', 'guest'),
  $oslomsg_use_ssl         = hiera('heat::rabbit_use_ssl', '0'),
) {
  # Domain resources will be created at step5 on the node running keystone.pp
  # configure heat.conf at step3 and 4 but actually create the domain later.
  if $step >= 3 {
    class { '::heat::keystone::domain':
      manage_domain => false,
      manage_user   => false,
      manage_role   => false,
    }

    $oslomsg_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_use_ssl)))

    class { '::heat' :
      notification_driver        => $notification_driver,
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_use_ssl_real,
      }),
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_use_ssl_real,
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

