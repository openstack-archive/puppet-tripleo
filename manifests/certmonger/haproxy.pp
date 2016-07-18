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
# [*postsave_cmd*]
#   The post-save-command that certmonger will use once it renews the
#   certificate.
#
# [*principal*]
#   The haproxy service principal that is set for HAProxy in kerberos.
#
define tripleo::certmonger::haproxy (
  $service_pem,
  $service_certificate,
  $service_key,
  $hostname,
  $postsave_cmd,
  $principal = undef,
){
    certmonger_certificate { "${title}-cert":
      hostname     => $hostname,
      certfile     => $service_certificate,
      keyfile      => $service_key,
      postsave_cmd => $postsave_cmd,
      principal    => $principal,
    }
    concat { $service_pem :
      ensure => present,
      mode   => '0640',
      owner  => 'haproxy',
      group  => 'haproxy',
    }
    concat::fragment { "${title}-cert-fragment":
      target  => $service_pem,
      source  => $service_certificate,
      order   => '01',
      require => Certmonger_certificate["${title}-cert"],
    }
    concat::fragment { "${title}-key-fragment":
      target  => $service_pem,
      source  => $service_key,
      order   => 10,
      require => Certmonger_certificate["${title}-cert"],
    }
}
