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
# == Class: tripleo::cluster::zookeeper
#
# Deploys a zookeeper service that belongs to a cluster. Uses deric-zookeeper
#
# == Parameters:
#
# [*zookeeper_server_ips*]
#  (required) List of IP addresses of the zookeeper cluster.
#  Arrays of strings value.
#
# [*zookeeper_client_ip*]
#  (required) IP address of the host where zookeeper will listen IP addresses.
#  String (IPv4) value.
#
# [*zookeeper_hostnames*]
#  (required) List of hostnames of the zookeeper cluster. The hostname of the
#  node will be used to define the ID of the zookeeper configuration
#  Array of strings value.
#

class tripleo::cluster::zookeeper(
  $zookeeper_server_ips,
  $zookeeper_client_ip,
  $zookeeper_hostnames
)
{
  # TODO: Remove comments below once we can guarantee that all the distros
  # deploying TripleO use Puppet > 3.7 because of this bug:
  # https://tickets.puppetlabs.com/browse/PUP-1299

  # validate_array($zookeeper_server_ips)
  validate_ipv4_address($zookeeper_client_ip)
  # validate_array($zookeeper_hostnames)

  # TODO(devvesa) Zookeeper package should provide these paths,
  # remove this lines as soon as it will.
  file {['/usr/lib', '/usr/lib/zookeeper', '/usr/lib/zookeeper/bin/']:
    ensure => directory
  }

  file {'/usr/lib/zookeeper/bin/zkEnv.sh':
    ensure => link,
    target => '/usr/libexec/zkEnv.sh'
  }

  class {'::zookeeper':
    servers   => $zookeeper_server_ips,
    client_ip => $zookeeper_client_ip,
    id        => extract_id($zookeeper_hostnames, $::hostname),
    cfg_dir   => '/etc/zookeeper/conf',
  }

  File['/usr/lib/zookeeper/bin/zkEnv.sh'] -> Class['::zookeeper']
}
