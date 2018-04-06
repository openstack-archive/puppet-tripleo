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
# == Resource: tripleo::certmonger::haproxy
#
# Request a certificate for the HAProxy service and does the necessary logic to
# get it into a format that the service understands.
#
# === Parameters
#
# [*service_pem*]
#   The file in PEM format that the HAProxy service will use as a certificate.
#
# [*service_certificate*]
#   The certificate file that certmonger will be tracking.
#
# [*service_key*]
#   The key file that certmonger will use for the certificate.
#
# [*hostname*]
#   The hostname that certmonger will use as the common name for the
#   certificate.
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
# [*principal*]
#   The haproxy service principal that is set for HAProxy in kerberos.
#
# [*postsave_cmd*]
#   The post-save-command that certmonger will use once it renews the
#   certificate.
#
define tripleo::certmonger::haproxy (
  $service_pem,
  $service_certificate,
  $service_key,
  $hostname,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $dnsnames      = undef,
  $principal     = undef,
  $postsave_cmd  = undef,
){
    include ::certmonger
    include ::haproxy::params
    if $certmonger_ca == 'local' {
      if defined(Class['::haproxy']) {
        Class['::tripleo::certmonger::ca::local'] ~> Class['::haproxy']
      }
      $principal_real = undef
    } else {
      $principal_real = $principal
    }

    # If we have HAProxy in the resource catalog, we can use the haproxy user
    # and group.
    if defined(Class['::haproxy']) {
      $cert_user = 'haproxy'
      $cert_group = 'haproxy'
    # If it's not in the resource catalog, it means that we're running in
    # containers. So we have to rely on the container to set the appropriate
    # permissions.
    } else {
      $cert_user = 'root'
      $cert_group = 'root'
    }

    if $dnsnames {
      $dnsnames_real = $dnsnames
    } else {
      $dnsnames_real = $hostname
    }

    if $certmonger_ca == 'local' {
      $ca_fragment = $ca_pem
    } else {
      $ca_fragment = ''
    }

    $concat_pem = "cat ${service_certificate} ${ca_fragment} ${service_key} > ${service_pem}"
    if $postsave_cmd {
      $postsave_cmd_real = "${concat_pem} && ${postsave_cmd}"
    } else {
      $reload_haproxy_cmd = 'if systemctl -q is-active haproxy; then systemctl reload haproxy; else true; fi'
      $postsave_cmd_real = "${concat_pem} && ${reload_haproxy_cmd}"
    }

    certmonger_certificate { "${title}-cert":
      ensure       => 'present',
      ca           => $certmonger_ca,
      hostname     => $hostname,
      dnsname      => $dnsnames_real,
      certfile     => $service_certificate,
      keyfile      => $service_key,
      postsave_cmd => $postsave_cmd_real,
      principal    => $principal_real,
      eku          => ['id-kp-clientAuth', 'id-kp-serverAuth'],
      wait         => true,
      tag          => 'haproxy-cert',
      require      => Class['::certmonger'],
    }
    concat { $service_pem :
      ensure => present,
      mode   => '0640',
      owner  => $cert_user,
      group  => $cert_group,
      tag    => 'haproxy-cert',
    }
    Package<| name == $::haproxy::params::package_name |> -> Concat[$service_pem]

    concat::fragment { "${title}-cert-fragment":
      target  => $service_pem,
      source  => $service_certificate,
      order   => '01',
      tag     => 'haproxy-cert',
      require => Certmonger_certificate["${title}-cert"],
    }

    if $certmonger_ca == 'local' {
      $ca_pem = getparam(Class['tripleo::certmonger::ca::local'], 'ca_pem')
      concat::fragment { "${title}-ca-fragment":
        target  => $service_pem,
        source  => $ca_pem,
        order   => '10',
        tag     => 'haproxy-cert',
        require => Class['tripleo::certmonger::ca::local'],
      }
    }

    concat::fragment { "${title}-key-fragment":
      target  => $service_pem,
      source  => $service_key,
      order   => 20,
      tag     => 'haproxy-cert',
      require => Certmonger_certificate["${title}-cert"],
    }
}
