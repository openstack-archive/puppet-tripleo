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
# == Class: tripleo::certmonger::ca::qemu
#
# Sets the necessary file that will be used by qemu servers and
# clients.
#
# === Parameters:
#
# [*origin_ca_pem*]
#  (Optional) Path to the CA certificate that qemu will use. This is not
#  assumed automatically or uses the system CA bundle as is the case of other
#  services because a limitation with the file sizes in GNU TLS, which qemu
#  uses as a TLS backend.
#  Defaults to undef
#
# [*certmonger_ca*]
#   (Optional) The CA name that certmonger will use to generate qemu certificates.
#   If this is not local or IPA then is assumed to be an IPA sub-CA and will be
#   added to the certmonger CA list.
#   Defaults to hiera('certmonger_ca_qemu', 'local').
#
class tripleo::certmonger::ca::qemu(
  $origin_ca_pem = undef,
  $certmonger_ca = hiera('certmonger_ca_qemu', 'local'),
){
  if $origin_ca_pem {
    $ensure_file = 'link'
  } else {
    $ensure_file = 'absent'
  }
  file { '/etc/pki/qemu/ca-cert.pem':
    ensure => $ensure_file,
    mode   => '0644',
    target => $origin_ca_pem,
  }

  if ! ($certmonger_ca in [ 'local', 'IPA', 'ipa' ]) {
    $wrapper_path = '/usr/libexec/certmonger/cm_ipa_subca_wrapper'
    $ipa_helper_path = '/usr/libexec/certmonger/ipa-submit'
    file { $wrapper_path:
      source => 'puppet:///modules/tripleo/cm_ipa_subca_wrapper.py',
      mode   => '0755',
      notify => Service['certmonger']
    }
    -> exec { "Add ${certmonger_ca} IPA subCA to certmonger":
      command => "getcert add-ca -c ${certmonger_ca} -e '${wrapper_path} ${certmonger_ca} ${ipa_helper_path}'",
      path    => ['/usr/bin', '/bin'],
      unless  => "getcert list-cas -c ${certmonger_ca} | grep '${wrapper_path} ${certmonger_ca}'",
      notify  => Service['certmonger']
    }
  }
}
