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
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*management_store*]
#   (Optional) The management store for Zaqar.
#   Defaults to 'mongodb'
#
# [*messaging_store*]
#   (Optional) The messaging store for Zaqar.
#   Defaults to 'mongodb'
#
# [*certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Example with hiera:
#     apache_certificates_specs:
#       httpd-internal_api:
#         hostname: <overcloud controller fqdn>
#         service_certificate: <service certificate path>
#         service_key: <service key path>
#         principal: "haproxy/<overcloud controller fqdn>"
#   Defaults to hiera('apache_certificate_specs', {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*zaqar_api_network*]
#   (Optional) The network name where the zaqar API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('zaqar_api_network', undef)
#
# [*zaqar_redis_password*]
#  (Optional) Password for the gnocchi redis user for the coordination url
#  Defaults to hiera('zaqar_redis_password')
#
# [*redis_vip*]
#  (Optional) Redis ip address for the coordination url
#  Defaults to hiera('redis_vip')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::zaqar (
  $bootstrap_node       = hiera('bootstrap_nodeid', undef),
  $management_store     = 'mongodb',
  $messaging_store      = 'mongodb',
  $certificates_specs   = hiera('apache_certificates_specs', {}),
  $enable_internal_tls  = hiera('enable_internal_tls', false),
  $zaqar_api_network    = hiera('zaqar_api_network', undef),
  $zaqar_redis_password = hiera('zaqar_redis_password', undef),
  $redis_vip            = hiera('redis_vip', undef),
  $step                 = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $is_bootstrap = true
  } else {
    $is_bootstrap = false
  }

  if $enable_internal_tls {
    if !$zaqar_api_network {
      fail('zaqar_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${zaqar_api_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${zaqar_api_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 4 or ( $step >= 3 and $is_bootstrap ) {
    include ::zaqar

    if $messaging_store == 'mongodb' or $management_store == 'mongodb' {
      if str2bool(hiera('mongodb::server::ipv6', false)) {
        $mongo_node_ips_with_port_prefixed = prefix(hiera('mongodb_node_ips'), '[')
        $mongo_node_ips_with_port = suffix($mongo_node_ips_with_port_prefixed, ']:27017')
      } else {
        $mongo_node_ips_with_port = suffix(hiera('mongodb_node_ips'), ':27017')
      }
      $mongodb_replset = hiera('mongodb::server::replset')
      $mongo_node_string = join($mongo_node_ips_with_port, ',')
      $mongo_database_connection = "mongodb://${mongo_node_string}/zaqar?replicaSet=${mongodb_replset}"
    }


    if $messaging_store == 'swift' {
      include ::zaqar::messaging::swift
    } elsif $messaging_store == 'mongodb' {
      class {'::zaqar::messaging::mongodb':
        uri => $mongo_database_connection,
      }
    } elsif $messaging_store == 'redis' {
      class {'::zaqar::messaging::redis':
        uri => join(['redis://:', $zaqar_redis_password, '@', normalize_ip_for_uri($redis_vip), ':6379/']),
      }
    } else {
      fail("unsupported Zaqar messaging_store set: ${messaging_store}")
    }

    if $management_store == 'sqlalchemy' {
      include ::zaqar::management::sqlalchemy
    } elsif $management_store == 'mongodb' {
      class { '::zaqar::management::mongodb':
        uri => $mongo_database_connection,
      }
    } else {
      fail("unsupported Zaqar management_store set: ${management_store}")
    }

    include ::zaqar::transport::websocket
    include ::tripleo::profile::base::apache
    include ::zaqar::transport::wsgi

    # TODO (bcrochet): At some point, the transports should be split out to
    # separate services.
    class { '::zaqar::server':
      service_name => 'httpd', # TODO cleanup when passed by t-h-t.
    }
    class { '::zaqar::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
    zaqar::server_instance{ '1':
      transport => 'websocket'
    }
  }
}

