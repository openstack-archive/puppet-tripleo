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
# == Resource: tripleo::certmonger::qemu
#
# Request a certificate for quemu and do the necessary setup.
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
# [*file_owner*]
#   (Optional) The user which the certificate and key files belong to.
#   Defaults to 'root'
#
# [*postsave_cmd*]
#   (Optional) Specifies the command to execute after requesting a certificate.
#   Defaults to undef.
#
# [*principal*]
#   (Optional) The service principal that is set for the service in kerberos.
#   Defaults to undef
#
# [*cacertfile*]
#   (Optional) Specifies that path to write the CA cerftificate to.
#   Defaults to undef
#
define tripleo::certmonger::qemu (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca_qemu', 'local'),
  $cacertfile    = undef,
  $postsave_cmd  = undef,
  $principal     = undef,
) {
  include ::certmonger
  include ::nova::params

  certmonger_certificate { $name :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd,
    ca           => $certmonger_ca,
    cacertfile   => $cacertfile,
    wait         => true,
    tag          => 'qemu-cert',
    require      => Class['::certmonger'],
  }

  file { $service_certificate :
    require => Certmonger_certificate[$name],
    mode    => '0644'
  }
  file { $service_key :
    require => Certmonger_certificate[$name],
    group   => 'qemu',
    mode    => '0640'
  }
}
