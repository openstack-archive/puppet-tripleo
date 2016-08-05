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
# == Class: tripleo::profile::pacemaker::gnocchi
#
# Gnocchi Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*gnocchi_indexer_backend*]
#   (Optional) Gnocchi indexer backend
#   Defaults to mysql
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::gnocchi (
  $bootstrap_node          = hiera('bootstrap_nodeid'),
  $gnocchi_indexer_backend = downcase(hiera('gnocchi_indexer_backend', 'mysql')),
  $step                    = hiera('step'),
) {
  Service <| tag == 'gnocchi-service' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $step >= 2 and $pacemaker_master {
    if $gnocchi_indexer_backend == 'mysql' {
      class { '::gnocchi::db::mysql':
        require => Exec['galera-ready'],
      }
    }
  }

  if $step >= 3 {
    include ::gnocchi
    include ::gnocchi::config
    include ::gnocchi::client
    if $pacemaker_master {
      include ::gnocchi::db::sync
    }
  }

  if $step >= 5 and $pacemaker_master {

    pacemaker::constraint::base { 'keystone-then-gnocchi-metricd-constraint':
      constraint_type => 'order',
      first_resource  => 'openstack-core-clone',
      second_resource => "${::gnocchi::params::metricd_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::gnocchi::params::metricd_service_name],
                          Pacemaker::Resource::Ocf['openstack-core']],
    }
    pacemaker::constraint::base { 'gnocchi-metricd-then-gnocchi-statsd-constraint':
      constraint_type => 'order',
      first_resource  => "${::gnocchi::params::metricd_service_name}-clone",
      second_resource => "${::gnocchi::params::statsd_service_name}-clone",
      first_action    => 'start',
      second_action   => 'start',
      require         => [Pacemaker::Resource::Service[$::gnocchi::params::metricd_service_name],
        Pacemaker::Resource::Service[$::gnocchi::params::statsd_service_name]],
    }
    pacemaker::constraint::colocation { 'gnocchi-statsd-with-metricd-colocation':
      source  => "${::gnocchi::params::statsd_service_name}-clone",
      target  => "${::gnocchi::params::metricd_service_name}-clone",
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service[$::gnocchi::params::metricd_service_name],
        Pacemaker::Resource::Service[$::gnocchi::params::statsd_service_name]],
    }
  }
}
