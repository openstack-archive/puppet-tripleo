#
# Copyright (C) 2015 Juniper Networks
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
# == Class: tripleo::network::contrail::control
#
# Configure Contrail Control services
#
# == Parameters:
#
# [*disc_server_ip*]
#  (required) IPv4 address of discovery server.
#  String (IPv4) value.
#
# [*host_ip*]
#  (required) host IP address of Database node
#  String (IPv4) value.
#
# [*disc_server_port*]
#  (required) port Discovery server listens on.
#  Integer value.
#  Defaults to 5998
#
class tripleo::network::contrail::database(
  $disc_server_ip = hiera('contrail::disc_server_ip'),
  $host_ip,
  $disc_server_port = hiera('contrail::disc_server_port'),
)
{
  class {'::contrail::database':
    database_nodemgr_config => {
      'DEFAULTS'  => {
        'hostip' => $host_ip,
      },
      'DISCOVERY' => {
        'port'   => $disc_server_port,
        'server' => $disc_server_ip,
      },
    },
  }
}
