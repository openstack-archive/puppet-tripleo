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
# == Class: tripleo::certmonger::ca::libvirt
#
# Sets the necessary file that will be used by both libvirt servers and
# clients.
#
# === Parameters:
#
# [*origin_ca_pem*]
#  (Optional) Path to the CA certificate that libvirt will use. This is not
#  assumed automatically or uses the system CA bundle as is the case of other
#  services because a limitation with the file sizes in GNU TLS, which libvirt
#  uses as a TLS backend.
#  Defaults to undef
#
class tripleo::certmonger::ca::libvirt(
  $origin_ca_pem = undef
){
  if $origin_ca_pem {
    $ensure_file = 'link'
  } else {
    $ensure_file = 'absent'
  }
  file { '/etc/pki/CA/cacert.pem':
    ensure => $ensure_file,
    mode   => '0644',
    target => $origin_ca_pem,
  }
}
