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
# == Class: tripleo::certmonger::mysql
#
# Request a certificate for the MySQL/Mariadb service and do the necessary setup.
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
#   This parameter can take both a string or an array of strings.
#   Defaults to $hostname
#
# [*postsave_cmd*]
#   (Optional) Specifies the command to execute after requesting a certificate.
#   If nothing is given, it will default to: "systemctl restart ${service name}"
#   Defaults to undef.
#
# [*principal*]
#   (Optional) The haproxy service principal that is set for MySQL in kerberos.
#   Defaults to undef
#
# [*key_size*]
#   (Optional) Specifies the private key size used when creating the certificate.
#   Defaults to 2048bits.
#
class tripleo::certmonger::mysql (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $dnsnames      = $hostname,
  $postsave_cmd  = undef,
  $principal     = undef,
  $key_size      = 2048,
) {
  include certmonger

  certmonger_certificate { 'mysql' :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $dnsnames,
    principal    => $principal,
    postsave_cmd => $postsave_cmd,
    ca           => $certmonger_ca,
    key_size     => $key_size,
    wait         => true,
    require      => Class['::certmonger'],
  }
}
