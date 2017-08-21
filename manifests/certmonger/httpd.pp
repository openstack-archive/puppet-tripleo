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
# == Resource: tripleo::certmonger::httpd
#
# Request a certificate for the httpd service and do the necessary setup.
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
# [*dnsnames*]
#   (Optional) The DNS names that will be added for the SubjectAltNames entry
#   in the certificate. If left unset, the value will be set to the $hostname.
#   Defaults to undef
#
# [*postsave_cmd*]
#   (Optional) Specifies the command to execute after requesting a certificate.
#   If nothing is given, it will default to: "systemctl restart ${service name}"
#   Defaults to undef.
#
# [*principal*]
#   The haproxy service principal that is set for HAProxy in kerberos.
#
define tripleo::certmonger::httpd (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $dnsnames      = undef,
  $postsave_cmd  = undef,
  $principal     = undef,
) {
  include ::certmonger
  include ::apache::params

  if $dnsnames {
    $dnsnames_real = $dnsnames
  } else {
    $dnsnames_real = $hostname
  }

  $postsave_cmd_real = pick($postsave_cmd, "systemctl reload ${::apache::params::service_name}")
  certmonger_certificate { $name :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $dnsnames_real,
    principal    => $principal,
    postsave_cmd => $postsave_cmd_real,
    ca           => $certmonger_ca,
    wait         => true,
    tag          => 'apache-cert',
    require      => Class['::certmonger'],
  }

  Certmonger_certificate[$name] ~> Service<| title == $::apache::params::service_name |>
}
