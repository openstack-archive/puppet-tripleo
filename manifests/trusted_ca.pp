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
# == Class: tripleo::trusted_ca
#
# Does the necessary action to deploy and trust a CA certificate.
#
# === Parameters
#
# [*content*]
#   The content of the CA certificate in PEM format.
#
define tripleo::trusted_ca(
  $content,
) {
  file { "/etc/pki/ca-trust/source/anchors/${name}.pem":
    content => $content,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }
  exec { "trust-ca-${name}":
    command     => 'update-ca-trust extract',
    path        => '/usr/bin',
    subscribe   => File["/etc/pki/ca-trust/source/anchors/${name}.pem"],
    refreshonly => true,
  }
}
