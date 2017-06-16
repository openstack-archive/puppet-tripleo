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
# == Class: tripleo::profile::base::cinder::volume::pure
#
# Cinder Volume pure profile for tripleo
#
# === Parameters
#
# [*san_ip*]
#   (required) IP address of PureStorage management VIP.
#
# [*pure_api_token*]
#   (required) API token for management of PureStorage array.
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_pure'
#
# [*pure_storage_protocol*]
#   (optional) Must be either 'iSCSI' or 'FC'. This will determine
#   which Volume Driver will be configured; PureISCSIDriver or PureFCDriver.
#   Defaults to 'iSCSI'
#
# [*use_multipath_for_image_xfer*]
#   (optional) .
#   Defaults to True
#
# [*use_chap_auth*]
#   (optional) Only affects the PureISCSIDriver.
#   Defaults to False
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::pure (
  $backend_name = hiera('cinder::backend::pure::volume_backend_name', 'tripleo_pure'),
  $step         = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::pure { $backend_name :
      san_ip                       => hiera('cinder::backend::pure::san_ip', undef),
      pure_api_token               => hiera('cinder::backend::pure::pure_api_token', undef),
      pure_storage_protocol        => hiera('cinder::backend::pure::pure_storage_protocol', undef),
      use_chap_auth                => hiera('cinder::backend::pure::use_chap_auth', undef),
      use_multipath_for_image_xfer => hiera('cinder::backend::pure::use_multipath_for_image_xfer', undef),
    }
  }

}
