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
#   Defaults to lookup('cinder::backend::pure::volume_backend_name', undef, undef, ['tripleo_pure'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::pure::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::pure (
  $backend_name = lookup('cinder::backend::pure::volume_backend_name', undef, undef, ['tripleo_pure']),
  $multi_config = lookup('cinder::backend::pure::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume

  if $step >= 4 {
    $backend_defaults = {
      'CinderPureAvailabilityZone'   => lookup('cinder::backend::pure::backend_availability_zone', undef, undef, undef),
      'CinderPureSanIp'              => lookup('cinder::backend::pure::san_ip', undef, undef, undef),
      'CinderPureAPIToken'           => lookup('cinder::backend::pure::pure_api_token', undef, undef, undef),
      'CinderPureStorageProtocol'    => lookup('cinder::backend::pure::pure_storage_protocol', undef, undef, undef),
      'CinderPureUseChap'            => lookup('cinder::backend::pure::use_chap_auth', undef, undef, undef),
      'CinderPureMultipathXfer'      => lookup('cinder::backend::pure::use_multipath_for_image_xfer', undef, undef, undef),
      'CinderPureImageCache'         => lookup('cinder::backend::pure::image_volume_cache_enabled', undef, undef, undef),
      'CinderPureIscsiCidr'          => lookup('cinder::backend::pure::pure_iscsi_cidr', undef, undef, undef),
      'CinderPureHostPersonality'    => lookup('cinder::backend::pure::pure_host_personality', undef, undef, undef),
      'CinderPureEradicateOnDelete'  => lookup('cinder::backend::pure::pure_eradicate_on_delete', undef, undef, undef),
      'CinderPureNvmeTransport'      => lookup('cinder::backend::pure::pure_nvme_transport', undef, undef, undef),
      'CinderPureNvmeCidr'           => lookup('cinder::backend::pure::pure_nvme_cidr', undef, undef, undef),
      'CinderPureNvmeCidrList'       => lookup('cinder::backend::pure::pure_nvme_cidr_list', undef, undef, undef),
    }

    $backend_name.each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::pure', { $backend => delete_undef_values({
        'backend_availability_zone'    => $backend_config['CinderPureAvailabilityZone'],
        'san_ip'                       => $backend_config['CinderPureSanIp'],
        'pure_api_token'               => $backend_config['CinderPureAPIToken'],
        'pure_storage_protocol'        => $backend_config['CinderPureStorageProtocol'],
        'use_chap_auth'                => $backend_config['CinderPureUseChap'],
        'use_multipath_for_image_xfer' => $backend_config['CinderPureMultipathXfer'],
        'image_volume_cache_enabled'   => $backend_config['CinderPureImageCache'],
        'pure_iscsi_cidr'              => $backend_config['CinderPureIscsiCidr'],
        'pure_host_personality'        => $backend_config['CinderPureHostPersonality'],
        'pure_eradicate_on_delete'     => $backend_config['CinderPureEradicateOnDelete'],
        'pure_nvme_transport'          => $backend_config['CinderPureNvmeTransport'],
        'pure_nvme_cidr'               => $backend_config['CinderPureNvmeCidr'],
        'pure_nvme_cidr_list'          => $backend_config['CinderPureNvmeCidrList'],
      })})
    }
  }
}
