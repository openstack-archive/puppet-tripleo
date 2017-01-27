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
# [*principal*]
#   (Optional) The haproxy service principal that is set for MySQL in kerberos.
#   Defaults to undef
#
class tripleo::certmonger::mysql (
  $hostname,
  $service_certificate,
  $service_key,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $principal     = undef,
) {
  include ::certmonger
  include ::mysql::params

  $postsave_cmd        = "systemctl reload ${::mysql::params::server_service_name}"
  certmonger_certificate { 'mysql' :
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
    owner   => 'mysql',
    group   => 'mysql',
    require => Certmonger_certificate['mysql'],
  }
  file { $service_key :
    owner   => 'mysql',
    group   => 'mysql',
    require => Certmonger_certificate['mysql'],
  }

  File[$service_certificate] ~> Service<| title == $::mysql::params::server_service_name |>
  File[$service_key] ~> Service<| title == $::mysql::params::server_service_name |>
}
