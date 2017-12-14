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
# == Class: tripleo::profile::base::ceilometer::collector
#
# Ceilometer Collector profile for tripleo
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
# [*ceilometer_backend*]
#   (Optional) The ceilometer backend to use.
#   Defaults to hiera('ceilometer_backend', 'mongodb')
#
# [*mongodb_ipv6*]
#   (Optional) Flag to indicate if mongodb is using ipv6
#   Defaults to hiera('mongodb::server::ipv6', false)
#
# [*mongodb_node_ips*]
#   (Optional) Array of mongodb node ip address. Required if backend is set
#   to mongodb.
#   Defaults to hiera('mongodb_node_ips', [])
#
# [*mongodb_replset*]
#   (Optional) Replica set for mongodb. Required if backend is mongodb
#   Defaults to hiera(''mongodb::server::replset', '')
#
class tripleo::profile::base::ceilometer::collector (
  $bootstrap_node     = hiera('bootstrap_nodeid', undef),
  $step               = hiera('step'),
  $ceilometer_backend = hiera('ceilometer_backend', 'mongodb'),
  $mongodb_ipv6       = hiera('mongodb::server::ipv6', false),
  $mongodb_node_ips   = hiera('mongodb_node_ips', []),
  $mongodb_replset    = hiera('mongodb::server::replset', undef)
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::ceilometer

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if downcase($ceilometer_backend) == 'mongodb' {
      if empty($mongodb_node_ips) {
        fail('Provided mongodb node ip addresses are empty')
      }
      if !$mongodb_replset {
        fail('mongodb_replset is required when using mongodb')
      }
      $mongo_nodes = suffix(any2array(normalize_ip_for_uri($mongodb_node_ips)), ':27017')
      $mongo_node_string = join($mongo_nodes, ',')
      $ceilometer_mongodb_conn_string = "mongodb://${mongo_node_string}/ceilometer?replicaSet=${mongodb_replset}"

      class { '::ceilometer::db' :
        sync_db             => $sync_db,
        database_connection => $ceilometer_mongodb_conn_string,
      }
    } else {
      class { '::ceilometer::db' :
        sync_db => $sync_db,
      }
    }
    include ::ceilometer::collector
    include ::ceilometer::dispatcher::gnocchi
  }

  # Re-run ceilometer-upgrade again in step 5 so gnocchi resource types
  # are created safely.
  if $step >= 5 and $sync_db {
    exec {'ceilometer-db-upgrade':
      command   => 'ceilometer-upgrade --skip-metering-database',
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

    # NOTE(sileht): Ensure we run before ceilometer-agent-notification and
    # ceilometer-collector rare started and after gnocchi-api is running
    include ::gnocchi::deps
    Anchor['gnocchi::service::end']
    ~> Exec['ceilometer-db-upgrade']
    ~> Service<| title == 'ceilometer-collector' |>
    ~> Service<| title == 'ceilometer-agent-notification' |>
    # NOTE(sileht): We can't depends on Anchor['ceilometer::service::begin']
    # directly because that will depends on ceilometer-api and creates a dep
    # loops across httpd, so we directly depends on the Services
  }
}
