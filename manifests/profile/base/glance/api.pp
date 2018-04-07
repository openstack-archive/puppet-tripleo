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
# == Class: tripleo::profile::base::glance::api
#
# Glance API profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
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
# [*glance_backend*]
#   (Optional) Glance backend(s) to use.
#   Defaults to downcase(hiera('glance_backend', 'swift'))
#
# [*glance_network*]
#   (Optional) The network name where the glance endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('glance_api_network', undef)
#
# [*glance_nfs_enabled*]
#   (Optional) Whether to use NFS mount as 'file' backend storage location.
#   Defaults to false
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('rabbitmq_node_names', undef)
#
# [*oslomsg_rpc_hosts*]
#   list of the oslo messaging rpc host fqdns
#   Defaults to hiera('oslo_messaging_rpc_node_names', undef)
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('glance::notify::rabbitmq::rabbit_port', 5672)
#
# [*tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. required only used if
#   enable_internal_tls is set.
#   defaults to undef
#
# [*tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   defaults to 9292
#
# [*glance_rbd_client_name*]
#   RBD client naem
#   (optional) Defaults to hiera('glance::backend::rbd::rbd_store_user')
class tripleo::profile::base::glance::api (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $glance_backend                = downcase(hiera('glance_backend', 'swift')),
  $glance_network                = hiera('glance_api_network', undef),
  $glance_nfs_enabled            = false,
  $step                          = Integer(hiera('step')),
  $rabbit_hosts                  = hiera('rabbitmq_node_names', undef),
  $oslomsg_rpc_hosts             = hiera('oslo_messaging_rpc_node_names', undef),
  $rabbit_port                   = hiera('glance::notify::rabbitmq::rabbit_port', 5672),
  $tls_proxy_bind_ip             = undef,
  $tls_proxy_fqdn                = undef,
  $tls_proxy_port                = 9292,
  $glance_rbd_client_name        = hiera('glance::backend::rbd::rbd_store_user','openstack'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $step >= 1 and $glance_nfs_enabled {
    include ::tripleo::glance::nfs_mount
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $enable_internal_tls {
      if !$glance_network {
        fail('glance_api_network is not set in the hieradata.')
      }
      if !$tls_proxy_bind_ip {
        fail('glance_api_tls_proxy_bind_ip is not set in the hieradata.')
      }
      if !$tls_proxy_fqdn {
        fail('tls_proxy_fqdn is required if internal TLS is enabled.')
      }
      $tls_certfile = $certificates_specs["httpd-${glance_network}"]['service_certificate']
      $tls_keyfile = $certificates_specs["httpd-${glance_network}"]['service_key']

      ::tripleo::tls_proxy { 'glance-api':
        servername => $tls_proxy_fqdn,
        ip         => $tls_proxy_bind_ip,
        port       => $tls_proxy_port,
        tls_cert   => $tls_certfile,
        tls_key    => $tls_keyfile,
        notify     => Class['::glance::api'],
      }
    }
    case $glance_backend {
        'swift': { $backend_store = 'swift' }
        'file': { $backend_store = 'file' }
        'rbd': {
          $backend_store = 'rbd'
          exec{ "exec-setfacl-${glance_rbd_client_name}-glance":
            path    => ['/bin', '/usr/bin'],
            command => "setfacl -m u:glance:r-- /etc/ceph/ceph.client.${glance_rbd_client_name}.keyring",
            unless  => "getfacl /etc/ceph/ceph.client.${glance_rbd_client_name}.keyring | grep -q user:glance:r--",
          }
          Ceph::Key<| title == "client.${glance_rbd_client_name}" |> -> Exec["exec-setfacl-${glance_rbd_client_name}-glance"]
        }
        'cinder': { $backend_store = 'cinder' }
        default: { fail('Unrecognized glance_backend parameter.') }
    }
    $http_store = ['http']
    $glance_store = concat($http_store, $backend_store)

    # TODO: notifications, scrubber, etc.
    include ::glance
    include ::glance::config
    # TODO(jaosorior): Remove bind_host when we set it up conditionally in t-h-t
    class { '::glance::api':
      stores  => $glance_store,
      sync_db => $sync_db,
    }
    $oslomsg_rpc_hosts_real = pick($rabbit_hosts, $oslomsg_rpc_hosts, [])
    $rabbit_endpoints = suffix(any2array($oslomsg_rpc_hosts_real), ":${rabbit_port}")
    class { '::glance::notify::rabbitmq' :
      rabbit_hosts => $rabbit_endpoints,
    }
    include join(['::glance::backend::', $glance_backend])
  }

}
