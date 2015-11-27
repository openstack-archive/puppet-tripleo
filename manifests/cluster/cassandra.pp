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
# == Class: tripleo::cluster::cassandra
#
# Deploys a cassandra service that belongs to a cluster. Uses puppet-cassandra
#
# == Parameters:
#
# [*cassandra_servers*]
#  (required) All the IP addresses of the cassandra cluster.
#  Array of strings value.
#
# [*cassandra_ip*]
#  (required) IP address of the current host.
#  String value
#
# [*storage_port*]
#  (optional) Inter-node cluster communication port.
#  Defaults to 7000.
#
# [*ssl_storage_port*]
#  (optional) SSL Inter-node cluster communication port.
#  Defaults to 7001.
#
# [*client_port*]
#  (optional) Cassandra client port.
#  Defaults to 9042.
#
# [*client_port_thrift*]
#  (optional) Cassandra client port thrift.
#  Defaults to 9160.
#
class tripleo::cluster::cassandra(
  $cassandra_servers,
  $cassandra_ip,
  $storage_port       = '7000',
  $ssl_storage_port   = '7001',
  $client_port        = '9042',
  $client_port_thrift = '9160'
)
{

  # TODO: Remove this comment once we can guarantee that all the distros
  # deploying TripleO use Puppet > 3.7 because of this bug:
  # https://tickets.puppetlabs.com/browse/PUP-1299
  #
  # validate_array($cassandra_servers)
  validate_ipv4_address($cassandra_ip)

  class {'::cassandra::run':
    seeds              => $cassandra_servers,
    seed_address       => $cassandra_ip,
    conf_dir           => '/etc/cassandra/default.conf',
    pid_dir            => '/var/run/cassandra',
    service_path       => '/sbin',
    storage_port       => $storage_port,
    ssl_storage_port   => $ssl_storage_port,
    client_port        => $client_port,
    client_port_thrift => $client_port_thrift
  }
}
