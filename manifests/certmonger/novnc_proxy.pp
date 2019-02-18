# Copyright 2018 Red Hat, Inc.
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
# == Class: tripleo::certmonger::novnc_proxy
#
# Request a certificate for MongoDB and do the necessary setup.
#
# === Parameters
#
# [*hostname*]
#   The hostname of the node. this will be set in the CN of the certificate.
#
# [*service_certificate*]
#   The path to the certificate that will be used for TLS in this service.
#
# [*service_key*]
#   The path to the key that will be used for TLS in this service.
#
# [*service_pem*]
#   The file in PEM format that the HAProxy service will use as a certificate.
#
# [*certmonger_ca*]
#   (Optional) The CA that certmonger will use to generate the certificates.
#   Defaults to hiera('certmonger_ca', 'local').
#
# [*postsave_cmd*]
#   (Optional) Specifies the command to execute after requesting a certificate.
#   Defaults to undef.
#
# [*principal*]
#   (Optional) The service principal that is set for the service in kerberos.
#   Defaults to undef
#
# [*notify_service*]
#   (Optional) Service to reload when certificate is created/renewed
#   Defaults to $::nova::params::libvirt_service_name
#
class tripleo::certmonger::novnc_proxy (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $notify_service   = undef,
  $postsave_cmd  = undef,
  $principal     = undef,
) {
  include ::certmonger
  include ::nova::params

  $notify_service_real = pick($notify_service, $::nova::params::vncproxy_service_name)

  ensure_resource('file', '/usr/bin/certmonger-novnc-proxy-refresh.sh', {
    source  => 'puppet:///modules/tripleo/certmonger-novnc-proxy-refresh.sh',
    mode    => '0700',
    seltype => 'bin_t',
    notify  => Service['certmonger']
  })

  certmonger_certificate { 'novnc-proxy' :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd,
    ca           => $certmonger_ca,
    wait         => true,
    tag          => 'novnc-proxy',
    require      => Class['::certmonger'],
  }

  file { $service_certificate :
    require => Certmonger_certificate['novnc-proxy'],
    mode    => '0644'
  }
  file { $service_key :
    require => Certmonger_certificate['novnc-proxy'],
    mode    => '0640'
  }

  File[$service_certificate] ~> Service<| title == $notify_service_real |>
  File[$service_key] ~> Service<| title == $notify_service_real |>
}
