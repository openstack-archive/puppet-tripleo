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
# == Class: tripleo::profile::base::designate
#
# Designate server profile for tripleo
#
# === Parameters
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
#   Defaults to hiera('designate::rabbit_port', 5672)
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to hiera('designate::rabbit_userid', 'guest')
#
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to hiera('designate::rabbit_password')
#
# [*oslomsg_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to hiera('designate::rabbit_use_ssl', '0')

class tripleo::profile::base::designate (
  $step                 = Integer(hiera('step')),
  $oslomsg_rpc_proto    = hiera('messaging_rpc_service_name', 'rabbit'),
  $oslomsg_rpc_hosts    = any2array(hiera('rabbitmq_node_names', undef)),
  $oslomsg_rpc_password = hiera('designate::rabbit_password'),
  $oslomsg_rpc_port     = hiera('designate::rabbit_port', '5672'),
  $oslomsg_rpc_username = hiera('designate::rabbit_userid', 'guest'),
  $oslomsg_use_ssl      = hiera('designate::rabbit_use_ssl', '0'),
) {
  if $step >= 3 {
    $oslomsg_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_use_ssl)))
    class { '::designate' :
      default_transport_url => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => sprintf('%s', $oslomsg_rpc_port),
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_use_ssl_real,
        }),
    }
    include ::designate::config
    include ::designate::backend::bind9
  }
}
