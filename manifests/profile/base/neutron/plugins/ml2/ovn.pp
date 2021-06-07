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
# == Class: tripleo::profile::base::neutron::plugins::ml2::ovn
#
# OVN Neutron ML2 profile for tripleo
#
# [*ovn_db_host*]
#   The IP-Address where OVN DBs are listening.
#   Defaults to hiera('ovn_dbs_vip')
#
# [*ovn_nb_port*]
#   (Optional) Port number on which northbound database is listening
#   Defaults to hiera('ovn::northbound::port')
#
# [*ovn_sb_port*]
#   (Optional) Port number on which southbound database is listening
#   Defaults to hiera('ovn::southbound::port')
#
# [*ovn_nb_private_key*]
#   (optional) The PEM file with private key for SSL connection to OVN-NB-DB
#   Defaults to $::os_service_default
#
# [*ovn_nb_certificate*]
#   (optional) The PEM file with certificate that certifies the private
#   key specified in ovn_nb_private_key
#   Defaults to $::os_service_default
#
# [*ovn_nb_ca_cert*]
#   (optional) The PEM file with CA certificate that OVN should use to
#   verify certificates presented to it by SSL peers
#   Defaults to $::os_service_default
#
# [*ovn_sb_private_key*]
#   (optional) The PEM file with private key for SSL connection to OVN-SB-DB
#   Defaults to $::os_service_default
#
# [*ovn_sb_certificate*]
#   (optional) The PEM file with certificate that certifies the
#   private key specified in ovn_sb_private_key
#   Defaults to $::os_service_default
#
# [*ovn_sb_ca_cert*]
#   (optional) The PEM file with CA certificate that OVN should use to
#   verify certificates presented to it by SSL peers
#   Defaults to $::os_service_default
#
# [*protocol*]
#   (optional) Protocol use in communication with dbs
#   Defaults to tcp
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plugins::ml2::ovn (
  $ovn_db_host              = hiera('ovn_dbs_vip'),
  $ovn_nb_port              = hiera('ovn::northbound::port'),
  $ovn_sb_port              = hiera('ovn::southbound::port'),
  $ovn_nb_private_key       = $::os_service_default,
  $ovn_nb_certificate       = $::os_service_default,
  $ovn_nb_ca_cert           = $::os_service_default,
  $ovn_sb_private_key       = $::os_service_default,
  $ovn_sb_certificate       = $::os_service_default,
  $ovn_sb_ca_cert           = $::os_service_default,
  $protocol                 = 'tcp',
  $step                     = Integer(hiera('step'))
) {
  if $step >= 4 {
    class { 'neutron::plugins::ml2::ovn':
      ovn_nb_connection  => join(["${protocol}", normalize_ip_for_uri($ovn_db_host), "${ovn_nb_port}"], ':'),
      ovn_sb_connection  => join(["${protocol}", normalize_ip_for_uri($ovn_db_host), "${ovn_sb_port}"], ':'),
      ovn_nb_private_key => $ovn_nb_private_key,
      ovn_nb_certificate => $ovn_nb_certificate,
      ovn_nb_ca_cert     => $ovn_nb_ca_cert,
      ovn_sb_private_key => $ovn_sb_private_key,
      ovn_sb_certificate => $ovn_sb_certificate,
      ovn_sb_ca_cert     => $ovn_sb_ca_cert,
    }
  }
}

