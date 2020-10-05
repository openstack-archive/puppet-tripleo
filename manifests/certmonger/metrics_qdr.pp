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
# == Class: tripleo::certmonger::metrics_qdr
#
# Request a certificate for the MetricsQdr service and do the necessary setup.
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
# [*certmonger_ca*]
#   (Optional) The CA that certmonger will use to generate the certificates.
#   Defaults to hiera('certmonger_ca', 'local').
#
# [*postsave_cmd*]
#   (Optional) Specifies the command to execute after requesting a certificate.
#   If nothing is given, it will default to: "systemctl restart ${service name}"
#   Defaults to undef.
#
# [*principal*]
#   (Optional) The haproxy service principal that is set for metrics_qdr in kerberos.
#   Defaults to undef
#
class tripleo::certmonger::metrics_qdr (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $postsave_cmd  = undef,
  $principal     = undef,
) {
  include certmonger
  include qdr::params

  ensure_resource('file', '/usr/bin/certmonger-metrics-qdr-refresh.sh', {
    source  => 'puppet:///modules/tripleo/certmonger-metrics-qdr-refresh.sh',
    mode    => '0700',
    seltype => 'bin_t',
    notify  => Service['certmonger']
  })

  certmonger_certificate { 'metrics_qdr' :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd,
    ca           => $certmonger_ca,
    wait         => true,
    require      => Class['::certmonger'],
  }

  file { $service_certificate :
    require => Certmonger_certificate['metrics_qdr'],
  }
  file { $service_key :
    require => Certmonger_certificate['metrics_qdr'],
  }

  File[$service_certificate] ~> Service<| title == $::qdr::params::service_name |>
  File[$service_key] ~> Service<| title == $::qdr::params::service_name |>
}
