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
# == Class: tripleo::profile::base::zaqar
#
# Zaqar profile for tripleo
#
# === Parameters
#
# [*sync_db*]
#   (Optional) Whether to run db sync
#   Defaults to true
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::zaqar (
  $step             = hiera('step'),
) {
  if $step >= 4  {
    include ::zaqar

    if str2bool(hiera('mongodb::server::ipv6', false)) {
      $mongo_node_ips_with_port_prefixed = prefix(hiera('mongodb_node_ips'), '[')
      $mongo_node_ips_with_port = suffix($mongo_node_ips_with_port_prefixed, ']:27017')
    } else {
      $mongo_node_ips_with_port = suffix(hiera('mongodb_node_ips'), ':27017')
    }
    $mongodb_replset = hiera('mongodb::server::replset')
    $mongo_node_string = join($mongo_node_ips_with_port, ',')
    $database_connection = "mongodb://${mongo_node_string}/zaqar?replicaSet=${mongodb_replset}"

    class { '::zaqar::management::mongodb':
      uri => $database_connection,
    }
    class {'::zaqar::messaging::mongodb':
      uri => $database_connection,
    }
    include ::zaqar::transport::websocket
    include ::apache::mod::ssl
    include ::zaqar::transport::wsgi

    # TODO (bcrochet): At some point, the transports should be split out to
    # separate services.
    class { '::zaqar::server':
      service_name => 'httpd', # TODO cleanup when passed by t-h-t.
    }
    include ::zaqar::wsgi::apache
    zaqar::server_instance{ '1':
      transport => 'websocket'
    }
  }
}

