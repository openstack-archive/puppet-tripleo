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
# == Class: tripleo::profile::base::octavia
#
# Octavia server profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*rabbit_user*]
# [*rabbit_password*]
#  (Optional) RabbitMQ user details
#  Defaults to undef
#
# [*rabbit_hosts*]
#   list of the rabbbit host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to 5672.
#
class tripleo::profile::base::octavia (
  $step            = hiera('step'),
  $rabbit_user     = undef,
  $rabbit_password = undef,
  $rabbit_hosts    = hiera('rabbitmq_node_names', undef),
  $rabbit_port     = '5672'
) {
  if $step >= 3 {
    class { '::octavia' :
      default_transport_url => os_transport_url({
        'transport' => 'rabbit',
        'hosts'     => $rabbit_hosts,
        'port'      => sprintf('%s', $rabbit_port),
        'username'  => $rabbit_user,
        'password'  => $rabbit_password
        })
    }
    include ::octavia::config
  }
}
