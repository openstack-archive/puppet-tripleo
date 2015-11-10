#
# Copyright (C) 2015 Midokura SARL
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
# == Class: tripleo::network::midonet::agent
#
# Configure the midonet agent
#
# == Parameters:
#
# [*zookeeper_servers*]
#  (required) List of IPs of the zookeeper server cluster. It will configure
#  the connection using the 2181 port.
#  Array of strings value.
#
# [*cassandra_seeds*]
#  (required) List of IPs of the cassandra cluster.
#  Array of strings value.
#
class tripleo::network::midonet::agent (
  $zookeeper_servers,
  $cassandra_seeds
) {

  validate_array($zookeeper_servers)
  validate_array($cassandra_seeds)

  # FIXME: This statement should be controlled by hiera on heat templates
  # project
  # Make sure openvswitch service is not running
  service {'openvswitch':
    ensure => stopped,
    enable => false
  }

  exec {'delete datapaths':
    command => '/usr/bin/mm-dpctl --delete-dp ovs-system',
    path    => '/usr/bin:/usr/sbin:/bin',
    onlyif  => '/usr/bin/mm-dpctl --show-dp ovs-system'
  }

  # Configure and run the agent
  class {'::midonet::midonet_agent':
    zk_servers      => list_to_zookeeper_hash($zookeeper_servers),
    cassandra_seeds => $cassandra_seeds
  }

  Service['openvswitch'] -> Class['::midonet::midonet_agent::run']
  Exec['delete datapaths'] -> Class['::midonet::midonet_agent::run']
}
