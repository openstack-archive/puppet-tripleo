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
# == Class: tripleo::profile::pacemaker::rabbitmq
#
# RabbitMQ Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*erlang_cookie*]
#   (Optional) Content of erlang cookie.
#   Defaults to hiera('rabbitmq::erlang_cookie').
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::rabbitmq (
  $bootstrap_node = hiera('bootstrap_nodeid'),
  $erlang_cookie  = hiera('rabbitmq::erlang_cookie'),
  $step           = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::rabbitmq

  file { '/var/lib/rabbitmq/.erlang.cookie':
    ensure  => file,
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0400',
    content => $erlang_cookie,
    replace => true,
    require => Class['::rabbitmq'],
  }

  if $step >= 1 and $pacemaker_master and hiera('stack_action') == 'UPDATE' {
    tripleo::pacemaker::resource_restart_flag { 'rabbitmq-clone':
      subscribe => Class['rabbitmq::service'],
    }
  }

  if $step >= 2 and $pacemaker_master {
    pacemaker::resource::ocf { 'rabbitmq':
      ocf_agent_name  => 'heartbeat:rabbitmq-cluster',
      resource_params => 'set_policy=\'ha-all ^(?!amq\.).* {"ha-mode":"all"}\'',
      clone_params    => 'ordered=true interleave=true',
      meta_params     => 'notify=true',
      require         => Class['::rabbitmq'],
    }
  }
}
