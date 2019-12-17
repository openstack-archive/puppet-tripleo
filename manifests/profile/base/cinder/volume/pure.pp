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
# [*backend_name*]
#   (Optional) List of names given to the Cinder backend stanza.
#   Defaults to hiera('cinder::backend::pure::volume_backend_name', ['tripleo_pure'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to hiera('cinder::backend::pure::volume_multi_config', {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::pure (
  $backend_name = hiera('cinder::backend::pure::volume_backend_name', ['tripleo_pure']),
  $multi_config = hiera('cinder::backend::pure::volume_multi_config', {}),
  $step         = Integer(hiera('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderPureAvailabilityZone' => hiera('cinder::backend::pure::backend_availability_zone', undef),
      'CinderPureSanIp'            => hiera('cinder::backend::pure::san_ip', undef),
      'CinderPureAPIToken'         => hiera('cinder::backend::pure::pure_api_token', undef),
      'CinderPureStorageProtocol'  => hiera('cinder::backend::pure::pure_storage_protocol', undef),
      'CinderPureUseChap'          => hiera('cinder::backend::pure::use_chap_auth', undef),
      'CinderPureMultipathXfer'    => hiera('cinder::backend::pure::use_multipath_for_image_xfer', undef),
      'CinderPureImageCache'       => hiera('cinder::backend::pure::image_volume_cache_enabled', undef),
    }

    $backend_name.each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      cinder::backend::pure { $backend :
        backend_availability_zone    => $backend_config['CinderPureAvailabilityZone'],
        san_ip                       => $backend_config['CinderPureSanIp'],
        pure_api_token               => $backend_config['CinderPureAPIToken'],
        pure_storage_protocol        => $backend_config['CinderPureStorageProtocol'],
        use_chap_auth                => $backend_config['CinderPureUseChap'],
        use_multipath_for_image_xfer => $backend_config['CinderPureMultipathXfer'],
        image_volume_cache_enabled   => $backend_config['CinderPureImageCache'],
      }
    }
  }
}
