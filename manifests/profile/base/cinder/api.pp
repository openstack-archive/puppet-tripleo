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
# == Class: tripleo::profile::base::cinder::api
#
# Cinder API profile for tripleo
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
# [*cinder_api_network*]
#   (Optional) The network name where the cinder API endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to hiera('cinder_api_network', undef)
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*keymgr_backend*]
#   (Optional) The encryption key manager backend. The default value
#   ensures Cinder's legacy key manager is enabled when no hiera value is
#   specified.
#   Defaults to hiera('cinder::api::keymgr_backend', 'cinder.keymgr.conf_key_mgr.ConfKeyManager')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# DEPRECATED PARAMETERS
#
# [*keymgr_api_class*]
#   (Optional) Deprecated. The encryption key manager API class. The default value
#   ensures Cinder's legacy key manager is enabled when no hiera value is
#   specified.
#   Defaults to undef.
#
class tripleo::profile::base::cinder::api (
  $bootstrap_node                = hiera('bootstrap_nodeid', undef),
  $certificates_specs            = hiera('apache_certificates_specs', {}),
  $cinder_api_network            = hiera('cinder_api_network', undef),
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $keymgr_backend                = hiera('cinder::api::keymgr_backend', 'cinder.keymgr.conf_key_mgr.ConfKeyManager'),
  $step                          = Integer(hiera('step')),
  # DEPRECATED PARAMETERS
  $keymgr_api_class              = undef,
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::cinder

  if $enable_internal_tls {
    if !$cinder_api_network {
      fail('cinder_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${cinder_api_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${cinder_api_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $keymgr_api_class {
      warning('The keymgr_api_class parameter is deprecated, use keymgr_backend')
      $keymgr_backend_real = $keymgr_api_class
    } else {
      $keymgr_backend_real = $keymgr_backend
    }

    class { '::cinder::api':
      keymgr_backend => $keymgr_backend_real,
    }
    include ::tripleo::profile::base::apache
    class { '::cinder::wsgi::apache':
      ssl_cert => $tls_certfile,
      ssl_key  => $tls_keyfile,
    }
    include ::cinder::ceilometer
  }

}
