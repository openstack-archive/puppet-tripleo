# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::designate::api
#
# Designate API server profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
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
#   Defaults to lookup('apache_certificates_specs', undef, undef, {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to lookup('enable_internal_tls', undef, undef, false)
#
# [*designate_network*]
#   (Optional) The network name where the designate endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('designate_api_network', undef, undef, undef)
#
# DEPRECATED PARAMETERS
#
# [*listen_ip*]
#   (Optional) The IP on which the API should listen.  (now set by hiera via
#   designate::wsgi::apache)
#   Defaults to undef
#
# [*listen_port*]
#   (Optional) The port on which the API should listen. (no longer needed,
#   listen port gets default value from designate::wsgi::apache)
#   Defaults to undef
#
# [*configure_apache*]
#   (Optional) Whether apache is configured via puppet or not.
#   Defaults to lookup('configure_apache', undef, undef, true)
#
class tripleo::profile::base::designate::api (
  $step                = Integer(lookup('step')),
  $certificates_specs  = lookup('apache_certificates_specs', undef, undef, {}),
  $enable_internal_tls = lookup('enable_internal_tls', undef, undef, false),
  $designate_network   = lookup('designate_api_network', undef, undef, undef),
  $listen_ip           = undef,
  $listen_port         = undef,
  $configure_apache    = lookup('configure_apache', undef, undef, true),
) {
  include tripleo::profile::base::designate
  include tripleo::profile::base::designate::authtoken

  if $enable_internal_tls {
    if !$designate_network {
      fail('designate_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${designate_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${designate_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if ($step >= 3) {
    # TODO: remove once the tripleo heat template changes merge
    if $listen_ip and $listen_port {
      $listen_uri = normalize_ip_for_uri($listen_ip)
      class { 'designate::api':
        listen => "${listen_uri}:${listen_port}"
      }
    } else {
      if $configure_apache {
        include tripleo::profile::base::apache
        class { 'designate::wsgi::apache':
          ssl_cert => $tls_certfile,
          ssl_key  => $tls_keyfile
        }
      }
      include designate::api
    }
    include designate::healthcheck
  }
}
