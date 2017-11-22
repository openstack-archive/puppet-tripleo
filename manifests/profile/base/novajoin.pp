# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::novajoin
#
# novajoin vendordata plugin profile for tripleo
#
# === Parameters
#
# [*service_password*]
#   The password for the novajoin service.
#
# [*enable_ipa_client_install*]
#   Enable FreeIPA client installation for the node this runs on.
#   Defaults to false
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
# [*oslomsg_rpc_password*]
#   Password for oslo messaging rpc service
#   Defaults to undef
#
# [*oslomsg_rpc_port*]
#   IP port for oslo messaging rpc service
#   Defaults to '5672'
#
# [*oslomsg_rpc_username*]
#   Username for oslo messaging rpc service
#   Defaults to 'guest'
#
# [*oslomsg_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to '0'
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#

class tripleo::profile::base::novajoin (
  $service_password,
  $enable_ipa_client_install = false,
  $rabbit_hosts              = hiera('rabbitmq_node_names', undef),
  $oslomsg_rpc_proto         = hiera('messaging_rpc_service_name', 'rabbit'),
  $oslomsg_rpc_hosts         = hiera('oslo_messaging_rpc_node_names', undef),
  $oslomsg_rpc_password      = undef,
  $oslomsg_rpc_port          = '5672',
  $oslomsg_rpc_username      = 'guest',
  $oslomsg_use_ssl           = '0',
  $step                      = Integer(hiera('step')),
) {
  if $step >= 3 {
    $oslomsg_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_use_ssl)))
    $oslomsg_rpc_hosts_real = any2array(pick($rabbit_hosts, $oslomsg_rpc_hosts))
    class { '::nova::metadata::novajoin::api' :
      service_password          => $service_password,
      enable_ipa_client_install => $enable_ipa_client_install,
      transport_url             => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts_real,
        'port'      => sprintf('%s', $oslomsg_rpc_port),
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_use_ssl_real,
        }),
    }
  }
}
