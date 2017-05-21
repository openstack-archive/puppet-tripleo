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
# == Class: tripleo::profile::base::cinder::volume::scaleio
#
# Cinder Volume scaleio profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_scaleio'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::scaleio (
  $backend_name = hiera('cinder::backend::scaleio::volume_backend_name', 'tripleo_scaleio'),
  $step         = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::scaleio { $backend_name :
      sio_login                        => hiera('cinder::backend::scaleio::sio_login', undef),
      sio_password                     => hiera('cinder::backend::scaleio::sio_password', undef),
      sio_server_hostname              => hiera('cinder::backend::scaleio::sio_server_hostname', undef),
      sio_server_port                  => hiera('cinder::backend::scaleio::sio_server_port', undef),
      sio_verify_server_certificate    => hiera('cinder::backend::scaleio::sio_verify_server_certificate', undef),
      sio_server_certificate_path      => hiera('cinder::backend::scaleio::sio_server_certificate_path', undef),
      sio_protection_domain_name       => hiera('cinder::backend::scaleio::sio_protection_domain_name', undef),
      sio_protection_domain_id         => hiera('cinder::backend::scaleio::sio_protection_domain_id', undef),
      sio_storage_pool_id              => hiera('cinder::backend::scaleio::sio_storage_pool_id', undef),
      sio_storage_pool_name            => hiera('cinder::backend::scaleio::sio_storage_pool_name', undef),
      sio_storage_pools                => hiera('cinder::backend::scaleio::sio_storage_pools', undef),
      sio_round_volume_capacity        => hiera('cinder::backend::scaleio::sio_round_volume_capacity', undef),
      sio_unmap_volume_before_deletion => hiera('cinder::backend::scaleio::sio_unmap_volume_before_deletion', undef),
      sio_max_over_subscription_ratio  => hiera('cinder::backend::scaleio::sio_max_over_subscription_ratio', undef),
      sio_thin_provision               => hiera('cinder::backend::scaleio::sio_thin_provision', undef),
    }
  }

}
