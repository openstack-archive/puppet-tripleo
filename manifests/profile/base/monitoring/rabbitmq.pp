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
# == Class: tripleo::profile::base::sensu::rabbitmq
#
# RabbitMQ configuration for Sensu stack for TripleO
#
# === Parameters
#
# [*password*]
#   (Optional) String. Password to connect to RabbitMQ server
#   Defaults to hiera('rabbit_password', undef)
#
# [*user*]
#   (Optional) String. Username to connect to RabbitMQ server
#   Defaults to hiera('rabbit_username', 'sensu')
#
# [*vhost*]
#   (Optional) String. RabbitMQ vhost to be used by Sensu
#   Defaults to '/sensu'
#
class tripleo::profile::base::monitoring::rabbitmq (
  $password = hiera('monitoring_rabbitmq_password', undef),
  $user     = hiera('monitoring_rabbitmq_username', 'sensu'),
  $vhost    = hiera('monitoring_rabbitmq_vhost', '/sensu'),
) {
  rabbitmq_vhost { 'sensu-rabbit-vhost':
    ensure => present,
    name   => $vhost
  }

  rabbitmq_user { 'sensu-rabbit-user':
    name     => $user,
    password => $password,
    tags     => ['monitoring']
  }

  rabbitmq_user_permissions { "${user}@${vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }
}
