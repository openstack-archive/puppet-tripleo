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
#   Defaults to lookup('cinder::backend::dellsc_iscsi::volume_backend_name', undef, undef, 'tripleo_dellsc')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::dellsc (
  $backend_name = lookup('cinder::backend::dellsc_iscsi::volume_backend_name', undef, undef, 'tripleo_dellsc'),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  warning('The tripleo_dellsc class will be removed in V-Release, please use the tripleo_dellemc_sc resource instead.')

  if $step >= 4 {

    # Include support for 'excluded_domain_ip' until it's deprecated in THT
    $excluded_domain_ip = lookup('cinder::backend::dellsc_iscsi::excluded_domain_ip', undef, undef, undef)
    $excluded_domain_ips = lookup('cinder::backend::dellsc_iscsi::excluded_domain_ips', undef, undef, undef)
    $excluded_domain_ips_real = pick_default($excluded_domain_ips, $excluded_domain_ip, undef)

    create_resources('cinder::backend::dellsc_iscsi', { $backend_name => delete_undef_values({
      'backend_availability_zone'    => lookup('cinder::backend::dellsc_iscsi::backend_availability_zone', undef, undef, undef),
      'san_ip'                       => lookup('cinder::backend::dellsc_iscsi::san_ip', undef, undef, undef),
      'san_login'                    => lookup('cinder::backend::dellsc_iscsi::san_login', undef, undef, undef),
      'san_password'                 => lookup('cinder::backend::dellsc_iscsi::san_password', undef, undef, undef),
      'dell_sc_ssn'                  => lookup('cinder::backend::dellsc_iscsi::dell_sc_ssn', undef, undef, undef),
      'target_ip_address'            => lookup('cinder::backend::dellsc_iscsi::iscsi_ip_address', undef, undef, undef),
      'target_port'                  => lookup('cinder::backend::dellsc_iscsi::iscsi_port', undef, undef, undef),
      'dell_sc_api_port'             => lookup('cinder::backend::dellsc_iscsi::dell_sc_api_port', undef, undef, undef),
      'dell_sc_server_folder'        => lookup('cinder::backend::dellsc_iscsi::dell_sc_server_folder', undef, undef, undef),
      'dell_sc_volume_folder'        => lookup('cinder::backend::dellsc_iscsi::dell_sc_volume_folder', undef, undef, undef),
      'excluded_domain_ips'          => $excluded_domain_ips_real,
      'secondary_san_ip'             => lookup('cinder::backend::dellsc_iscsi::secondary_san_ip', undef, undef, undef),
      'secondary_san_login'          => lookup('cinder::backend::dellsc_iscsi::secondary_san_login', undef, undef, undef),
      'secondary_san_password'       => lookup('cinder::backend::dellsc_iscsi::secondary_san_password', undef, undef, undef),
      'secondary_sc_api_port'        => lookup('cinder::backend::dellsc_iscsi::secondary_sc_api_port', undef, undef, undef),
      'use_multipath_for_image_xfer' => lookup('cinder::backend::dellsc_iscsi::use_multipath_for_image_xfer', undef, undef, undef),
    })})
  }

}
