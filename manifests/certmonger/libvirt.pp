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
# == Resource: tripleo::certmonger::libvirt
#
# Request a certificate for libvirt and do the necessary setup.
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
#   If nothing is given, it will default to: "systemctl reload ${service name}"
#   Defaults to undef.
#
# [*principal*]
#   (Optional) The service principal that is set for the service in kerberos.
#   Defaults to undef
#
define tripleo::certmonger::libvirt (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $postsave_cmd  = undef,
  $principal     = undef,
) {
  include ::certmonger
  include ::nova::params

  $postsave_cmd_real = pick($postsave_cmd, "systemctl reload ${::nova::params::libvirt_service_name}")
  certmonger_certificate { $name :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd_real,
    ca           => $certmonger_ca,
    wait         => true,
    tag          => 'libvirt-cert',
    require      => Class['::certmonger'],
  }

  # Just register the files in puppet's resource catalog. Certmonger should
  # give the right permissions.
  file { $service_certificate :
    require => Certmonger_certificate[$name],
  }
  file { $service_key :
    require => Certmonger_certificate[$name],
  }

  File[$service_certificate] ~> Service<| title == $::nova::params::libvirt_service_name |>
  File[$service_key] ~> Service<| title == $::nova::params::libvirt_service_name |>
}
