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
#
# [*oslomsg_notify_proto*]
#   Protocol driver for the oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit')
#
# [*oslomsg_notify_hosts*]
#   list of the oslo messaging notify host fqdns
#   Defaults to any2array(lookup('oslo_messaging_notify_node_names', undef, undef, undef))
#
# [*oslomsg_notify_port*]
#   IP port for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_port', undef, undef, '5672')
#
# [*oslomsg_notify_username*]
#   Username for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_user_name', undef, undef, 'guest')
#
# [*oslomsg_notify_password*]
#   Password for oslo messaging notify service
#   Defaults to lookup('oslo_messaging_notify_password')
#
# [*oslomsg_notify_use_ssl*]
#   Enable ssl oslo messaging services
#   Defaults to lookup('oslo_messaging_notify_use_ssl', undef, undef, '0')
#
# [* DEPRECATED PARAMETERS *]
#
# [*rndc_host*]
#   The address on which rndc should listen
#   Defaults to undef
#
# [*rndc_port*]
#   The port on which rndc should listen
#   Defaults undef
#
# [*rndc_keys*]
#   A list of keys that rndc should accept
#   Defaults to undef
#
# [*rndc_allowed_addresses*]
#   A list of addresses that are allowed to send rndc commands
#   Defaults to undef
#
class tripleo::profile::base::designate (
  $step                    = Integer(lookup('step')),
  $oslomsg_rpc_proto       = lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit'),
  $oslomsg_rpc_hosts       = any2array(lookup('oslo_messaging_rpc_node_names', undef, undef, undef)),
  $oslomsg_rpc_password    = lookup('oslo_messaging_rpc_password'),
  $oslomsg_rpc_port        = lookup('oslo_messaging_rpc_port', undef, undef, '5672'),
  $oslomsg_rpc_username    = lookup('oslo_messaging_rpc_user_name', undef, undef, 'guest'),
  $oslomsg_rpc_use_ssl     = lookup('oslo_messaging_rpc_use_ssl', undef, undef, '0'),
  $oslomsg_notify_proto    = lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit'),
  $oslomsg_notify_hosts    = any2array(lookup('oslo_messaging_notify_node_names', undef, undef, undef)),
  $oslomsg_notify_password = lookup('oslo_messaging_notify_password'),
  $oslomsg_notify_port     = lookup('oslo_messaging_notify_port', undef, undef, '5672'),
  $oslomsg_notify_username = lookup('oslo_messaging_notify_user_name', undef, undef, 'guest'),
  $oslomsg_notify_use_ssl  = lookup('oslo_messaging_notify_use_ssl', undef, undef, '0'),
  # DEPRECATED PARAMETERS
  $rndc_host               = undef,
  $rndc_port               = undef,
  $rndc_keys               = undef,
  $rndc_allowed_addresses  = undef,
) {
  if $step >= 3 {
    $oslomsg_rpc_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_rpc_use_ssl)))
    $oslomsg_notify_use_ssl_real = sprintf('%s', bool2num(str2bool($oslomsg_notify_use_ssl)))
    class { 'designate' :
      default_transport_url      => os_transport_url({
        'transport' => $oslomsg_rpc_proto,
        'hosts'     => $oslomsg_rpc_hosts,
        'port'      => $oslomsg_rpc_port,
        'username'  => $oslomsg_rpc_username,
        'password'  => $oslomsg_rpc_password,
        'ssl'       => $oslomsg_rpc_use_ssl_real,
      }),
      notification_transport_url => os_transport_url({
        'transport' => $oslomsg_notify_proto,
        'hosts'     => $oslomsg_notify_hosts,
        'port'      => $oslomsg_notify_port,
        'username'  => $oslomsg_notify_username,
        'password'  => $oslomsg_notify_password,
        'ssl'       => $oslomsg_notify_use_ssl_real,
      }),
    }
    if ($rndc_host or $rndc_allowed_addresses or $rndc_keys or $rndc_allowed_addresses) {
      warning('rndc/named configuration through puppet is no longer supported.')
    }
    include designate::config
    include designate::logging
  }
}
