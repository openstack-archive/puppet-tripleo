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
# Request a certificate for novnc_proxy and do the necessary setup.
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
# [*key_size*]
#   (Optional) Specifies the private key size used when creating the certificate.
#   Defaults to 2048bits.
#
class tripleo::certmonger::novnc_proxy (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $notify_service   = undef,
  $postsave_cmd  = undef,
  $key_size      = 2048,
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

  file { $service_key :
    group => 'qemu',
    mode  => '0640',
    audit => [content],
  }
  ~> exec { "Purge ${service_certificate}" :
    command     => "rm -f ${service_certificate}",
    refreshonly => true,
    path        => '/usr/bin:/bin',
  }
  -> certmonger_certificate { 'novnc-proxy' :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd,
    ca           => $certmonger_ca,
    key_size     => $key_size,
    wait         => true,
    tag          => 'novnc-proxy',
    require      => Class['::certmonger'],
    subscribe    => File[$service_key],
  }

  exec { $service_certificate :
    require   => Certmonger_certificate['novnc-proxy'],
    command   => "test -f ${service_certificate}",
    unless    => "test -f ${service_certificate}",
    tries     => 60,
    try_sleep => 1,
    timeout   => 60,
    path      => '/usr/bin:/bin',
  }
  -> exec { "Change permissions and owner of ${service_key} and ${service_certificate}":
    command     => "chgrp qemu ${service_key} && chmod 0640 ${service_key} && chgrp qemu ${service_certificate} && chmod 0640 ${service_certificate}", # lint:ignore:140chars
    refreshonly => true,
    path        => '/usr/bin:/bin',
  }

  file { $service_certificate :
    group => 'qemu',
    mode  => '0644'
  }

  Certmonger_certificate['novnc-proxy'] ~> Exec["Change permissions and owner of ${service_key} and ${service_certificate}"]
  Exec["Purge ${service_certificate}"] -> File[$service_certificate] ~> Service<| title == $notify_service_real |>
  File[$service_key] ~> Service<| title == $notify_service_real |>
}
