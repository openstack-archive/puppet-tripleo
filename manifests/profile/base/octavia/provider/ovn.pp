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
# == Class: tripleo::profile::base::octavia::provider::ovn
#
# Octavia OVN provider profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*protocol*]
#   (optional) Protocol use in communication with dbs
#   Defaults to tcp
#
# [*ovn_db_host*]
#   (Optional) The IP-Address where OVN DBs are listening.
#   Defaults to hiera('ovn_dbs_vip')
#
# [*ovn_nb_port*]
#   (Optional) Port number on which northbound database is listening
#   Defaults to hiera('ovn::northbound::port')
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
class tripleo::profile::base::octavia::provider::ovn (
  $step               = Integer(hiera('step')),
  $protocol           = hiera('ovn_nb_connection_protocol', 'tcp'),
  $ovn_db_host        = hiera('ovn_dbs_vip', undef),
  $ovn_nb_port        = hiera('ovn::northbound::port', undef),
  $ovn_nb_private_key = $::os_service_default,
  $ovn_nb_certificate = $::os_service_default,
  $ovn_nb_ca_cert     = $::os_service_default
) {

  include tripleo::profile::base::octavia::api

  if ($step >= 4) {
    # For backward compatibility
    if $::tripleo::profile::base::octavia::api::ovn_db_host and !is_service_default(::tripleo::profile::base::octavia::api::ovn_db_host) {
      $ovn_db_host_real = $::tripleo::profile::base::octavia::api::ovn_db_host
      $ovn_nb_port_real = $::tripleo::profile::base::octavia::api::ovn_nb_port
    }
    else {
      $ovn_db_host_real = $ovn_db_host
      $ovn_nb_port_real = $ovn_nb_port
    }

    if $ovn_db_host_real {
      $ovn_nb_conn_args = ["${protocol}", normalize_ip_for_uri($ovn_db_host_real), "${ovn_nb_port_real}"].filter |$c| { !$c.empty() }
      $ovn_nb_connection = join($ovn_nb_conn_args, ':')
      class { 'octavia::provider::ovn':
        ovn_nb_connection  => $ovn_nb_connection,
        ovn_nb_private_key => $ovn_nb_private_key,
        ovn_nb_certificate => $ovn_nb_certificate,
        ovn_nb_ca_cert     => $ovn_nb_ca_cert,
      }
    }
  }
}
