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
# == Class: tripleo::profile::base::cinder::volume::dellsc
#
# Cinder Volume dellsc profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_dellsc'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::dellsc (
  $backend_name = hiera('cinder::backend::dellsc_iscsi::volume_backend_name', 'tripleo_dellsc'),
  $step         = Integer(hiera('step')),
) {
  include tripleo::profile::base::cinder::volume

  warning('The tripleo_dellsc class will be removed in V-Release, please use the triplo_dellemc_sc resource instead.')

  if $step >= 4 {

    # Include support for 'excluded_domain_ip' until it's deprecated in THT
    $excluded_domain_ip = hiera('cinder::backend::dellsc_iscsi::excluded_domain_ip', undef)
    $excluded_domain_ips = hiera('cinder::backend::dellsc_iscsi::excluded_domain_ips', undef)
    $excluded_domain_ips_real = pick_default($excluded_domain_ips, $excluded_domain_ip, undef)

    cinder::backend::dellsc_iscsi { $backend_name :
      backend_availability_zone    => hiera('cinder::backend::dellsc_iscsi::backend_availability_zone', undef),
      san_ip                       => hiera('cinder::backend::dellsc_iscsi::san_ip', undef),
      san_login                    => hiera('cinder::backend::dellsc_iscsi::san_login', undef),
      san_password                 => hiera('cinder::backend::dellsc_iscsi::san_password', undef),
      dell_sc_ssn                  => hiera('cinder::backend::dellsc_iscsi::dell_sc_ssn', undef),
      target_ip_address            => hiera('cinder::backend::dellsc_iscsi::iscsi_ip_address', undef),
      target_port                  => hiera('cinder::backend::dellsc_iscsi::iscsi_port', undef),
      dell_sc_api_port             => hiera('cinder::backend::dellsc_iscsi::dell_sc_api_port', undef),
      dell_sc_server_folder        => hiera('cinder::backend::dellsc_iscsi::dell_sc_server_folder', undef),
      dell_sc_volume_folder        => hiera('cinder::backend::dellsc_iscsi::dell_sc_volume_folder', undef),
      excluded_domain_ips          => $excluded_domain_ips_real,
      secondary_san_ip             => hiera('cinder::backend::dellsc_iscsi::secondary_san_ip', undef),
      secondary_san_login          => hiera('cinder::backend::dellsc_iscsi::secondary_san_login', undef),
      secondary_san_password       => hiera('cinder::backend::dellsc_iscsi::secondary_san_password', undef),
      secondary_sc_api_port        => hiera('cinder::backend::dellsc_iscsi::secondary_sc_api_port', undef),
      use_multipath_for_image_xfer => hiera('cinder::backend::dellsc_iscsi::use_multipath_for_image_xfer', undef),
    }
  }

}
