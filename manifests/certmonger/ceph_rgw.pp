# Copyright 2020 Red Hat, Inc.
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
# == Class: tripleo::certmonger::ceph_rgw
#
# Request a certificate for Ceph RGW and do the necessary setup.
#
# === Parameters
#
# [*hostname*]
#   The hostname of the node. this will be set in the CN of the certificate.
#
# [*service_pem*]
#   The file in PEM format that the HAProxy service will use as a certificate.
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
#   Defaults to undef.
#
# [*principal*]
#   (Optional) The service principal that is set for the service in kerberos.
#   Defaults to undef
#
# [*key_size*]
#   (Optional) Specifies the private key size used when creating the certificate.
#   Defaults to 2048bits.
#
class tripleo::certmonger::ceph_rgw (
  $hostname,
  $service_certificate,
  $service_key,
  $service_pem,
  $postsave_cmd = undef,
  $certmonger_ca = hiera('certmonger_ca', 'local'),
  $principal     = undef,
  $key_size      = 2048,
) {

  ensure_resource('file', '/usr/bin/certmonger-rgw-refresh.sh', {
    source  => 'puppet:///modules/tripleo/certmonger-rgw-refresh.sh',
    mode    => '0700',
    seltype => 'bin_t',
    notify  => Service['certmonger']
  })

  certmonger_certificate { 'ceph_rgw' :
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
    require      => Class['::certmonger'],
  }

  concat { $service_pem :
    ensure => present,
    mode   => '0640',
    owner  => 472,
    group  => 472,
    tag    => 'ceph-rgw-cert',
  }

  concat::fragment { "${title}-cert-fragment":
    target  => $service_pem,
    source  => $service_certificate,
    order   => '01',
    tag     => 'ceph_rgw-cert',
    require => Concat["${service_pem}"]
  }

  if $certmonger_ca == 'local' {
    $ca_pem = getparam(Class['tripleo::certmonger::ca::local'], 'ca_pem')
    concat::fragment { "${title}-ca-fragment":
      target  => $service_pem,
      source  => $ca_pem,
      order   => '10',
      tag     => 'ceph_rgw-cert',
      require => [ Class['tripleo::certmonger::ca::local'], Concat::Fragment["${title}-cert-fragment"] ]
    }
  } elsif $certmonger_ca == 'IPA' {
    concat::fragment { "${title}-ca-fragment":
      target  => $service_pem,
      source  => '/etc/ipa/ca.crt',
      order   => '10',
      tag     => 'ceph_rgw-cert',
      require => Concat::Fragment["${title}-cert-fragment"]
    }
  }

  concat::fragment { "${title}-key-fragment":
    target  => $service_pem,
    source  => $service_key,
    order   => 20,
    tag     => 'ceph_rgw-cert',
    require => Concat::Fragment["${title}-ca-fragment"],
  }
}
