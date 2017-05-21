# Copyright 2016 Hewlett-Packard Enterprise.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::cinder::volume::hpelefthand
#
# Cinder Volume hpelefthand profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_hpelefthand'
#
# [*cinder_hpelefthand_api_url*]
#   (required) url for api access to lefthand - example https://10.x.x.x:8080/api/v1
#
# [*cinder_hpelefthand_username*]
#   (required) Username for HPElefthand admin user
#
# [*cinder_hpelefthand_password*]
#   (required) Password for hpelefthand_username
#
# [*cinder_hpelefthand_iscsi_chap_enabled*]
#   (required) setting to false by default
#
# [*cinder_hpelefthand_clustername*]
#   (required) clustername of hpelefthand
#
# [*cinder_hpelefthand_debug*]
#   (required) setting to false by default
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::hpelefthand (
  $backend_name                          = hiera('cinder::backend::hpelefthand_iscsi::volume_backend_name', 'tripleo_hpelefthand'),
  $cinder_hpelefthand_username           = hiera('cinder::backend::hpelefthand_iscsi::hpelefthand_username', undef),
  $cinder_hpelefthand_password           = hiera('cinder::backend::hpelefthand_iscsi::hpelefthand_password', undef),
  $cinder_hpelefthand_clustername        = hiera('cinder::backend::hpelefthand_iscsi::hpelefthand_clustername', undef),
  $cinder_hpelefthand_api_url            = hiera('cinder::backend::hpelefthand_iscsi::hpelefthand_api_url', undef),
  $cinder_hpelefthand_iscsi_chap_enabled = hiera('cinder::backend::hpelefthand_iscsi::hpelefthand_iscsi_chap_enabled', undef),
  $cinder_hpelefthand_debug              = hiera('cinder::backend::hpelefthand_iscsi::hpelefthand_debug', undef),
  $step                                  = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::hpelefthand_iscsi { $backend_name :
      hpelefthand_username           => $cinder_hpelefthand_username,
      hpelefthand_password           => $cinder_hpelefthand_password,
      hpelefthand_clustername        => $cinder_hpelefthand_clustername,
      hpelefthand_api_url            => $cinder_hpelefthand_api_url,
      hpelefthand_iscsi_chap_enabled => $cinder_hpelefthand_iscsi_chap_enabled,
      hpelefthand_debug              => $cinder_hpelefthand_debug,
    }
  }

}
