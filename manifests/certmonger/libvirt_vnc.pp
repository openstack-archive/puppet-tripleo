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
# == Resource: tripleo::certmonger::libvirt_vnc
#
# Request a certificate for libvirt-vnc and do the necessary setup.
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
#   Defaults to hiera('certmonger_ca_vnc', 'local').
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
# [*cacertfile*]
#   (Optional) Specifies that path to write the CA cerftificate to.
#   Defaults to undef
#
# [*notify_service*]
#   (Optional) Service to reload when certificate is created/renewed
#   Defaults to $::nova::params::libvirt_service_name
#
define tripleo::certmonger::libvirt_vnc (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca    = hiera('certmonger_ca_vnc', 'local'),
  $postsave_cmd     = undef,
  $principal        = undef,
  $cacertfile       = undef,
  $notify_service   = undef,
) {
  include ::certmonger
  include ::nova::params

  $notify_service_real = pick($notify_service, $::nova::params::libvirt_service_name)

  $postsave_cmd_real = pick($postsave_cmd, "systemctl reload ${notify_service_real}")

  certmonger_certificate { $name :
    ensure       => 'present',
    certfile     => $service_certificate,
    keyfile      => $service_key,
    hostname     => $hostname,
    dnsname      => $hostname,
    principal    => $principal,
    postsave_cmd => $postsave_cmd_real,
    ca           => $certmonger_ca,
    cacertfile   => $cacertfile,
    wait         => true,
    tag          => 'libvirt-cert',
    require      => Class['::certmonger'],
  }

  if $cacertfile {
    file { $cacertfile :
      require => Certmonger_certificate[$name],
      mode    => '0644'
    }
    ~> Service<| title == $notify_service_real |>
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

  File[$service_certificate] ~> Service<| title == $notify_service_real |>
  File[$service_key] ~> Service<| title == $notify_service_real |>
}
