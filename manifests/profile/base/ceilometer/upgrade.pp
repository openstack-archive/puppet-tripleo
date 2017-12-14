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
# == Class: tripleo::profile::base::ceilometer::upgrade
#
# Ceilometer upgrade profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#

class tripleo::profile::base::ceilometer::upgrade (
  $bootstrap_node = hiera('bootstrap_nodeid', undef),
  $step           = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 5 and $sync_db {
    exec {'ceilometer-db-upgrade':
      command   => 'ceilometer-upgrade',
      path      => ['/usr/bin', '/usr/sbin'],
      # LP#1703444 - When this runs, it talks to gnocchi on all controllers
      # which then reaches out to keystone via haproxy. Since the deployment
      # may restart httpd on these other nodes it can result in an intermittent
      # 503 which fails this command. We should retry the upgrade in case of
      # error since we cannot ensure that there might not be some other deploy
      # process running on the other nodes.
      try_sleep => 5,
      tries     => 10
    }

    # NOTE(sileht): Ensure we run before ceilometer-agent-notification is
    # started and after gnocchi-api is running
    include ::gnocchi::deps
    Anchor['gnocchi::service::end']
    ~> Exec['ceilometer-db-upgrade']
    ~> Anchor['ceilometer::service::begin']
  }
}
