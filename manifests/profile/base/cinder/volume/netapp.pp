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
# == Class: tripleo::profile::base::cinder::volume::netapp
#
# Cinder Volume netapp profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_netapp'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::netapp (
  $backend_name = hiera('cinder::backend::netapp::volume_backend_name', 'tripleo_netapp'),
  $step         = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    if hiera('cinder::backend::netapp::nfs_shares', undef) {
      $cinder_netapp_nfs_shares = split(hiera('cinder::backend::netapp::nfs_shares', undef), ',')
    }

    # fallback logic for search patterns since upstream puppet-cinder removed
    # these.  See I286a593f0e68dc9e60852674d2fa14551acb1bbb from puppet-cinder
    $list = join(any2array(delete(delete_undef_values([
      hiera('cinder::backend::netapp::netapp_storage_pools', undef),
      hiera('cinder::backend::netapp::netapp_volume_list', undef),
    ]), '')),'|')
    if $list != '' {
      $netapp_pool_name_search_pattern_fallback = "(${list})"
    } else {
      $netapp_pool_name_search_pattern_fallback = undef
    }
    cinder::backend::netapp { $backend_name :
      netapp_login                    => hiera('cinder::backend::netapp::netapp_login', undef),
      netapp_password                 => hiera('cinder::backend::netapp::netapp_password', undef),
      netapp_server_hostname          => hiera('cinder::backend::netapp::netapp_server_hostname', undef),
      netapp_server_port              => hiera('cinder::backend::netapp::netapp_server_port', undef),
      netapp_size_multiplier          => hiera('cinder::backend::netapp::netapp_size_multiplier', undef),
      netapp_storage_family           => hiera('cinder::backend::netapp::netapp_storage_family', undef),
      netapp_storage_protocol         => hiera('cinder::backend::netapp::netapp_storage_protocol', undef),
      netapp_transport_type           => hiera('cinder::backend::netapp::netapp_transport_type', undef),
      netapp_vfiler                   => hiera('cinder::backend::netapp::netapp_vfiler', undef),
      netapp_vserver                  => hiera('cinder::backend::netapp::netapp_vserver', undef),
      netapp_partner_backend_name     => hiera('cinder::backend::netapp::netapp_partner_backend_name', undef),
      nfs_shares                      => $cinder_netapp_nfs_shares,
      nfs_shares_config               => hiera('cinder::backend::netapp::nfs_shares_config', undef),
      nfs_mount_options               => hiera('cinder::backend::netapp::nfs_mount_options', undef),
      netapp_copyoffload_tool_path    => hiera('cinder::backend::netapp::netapp_copyoffload_tool_path', undef),
      netapp_controller_ips           => hiera('cinder::backend::netapp::netapp_controller_ips', undef),
      netapp_sa_password              => hiera('cinder::backend::netapp::netapp_sa_password', undef),
      netapp_host_type                => hiera('cinder::backend::netapp::netapp_host_type',
                                                hiera('cinder::backend::netapp::netapp_eseries_host_type', undef)),
      netapp_webservice_path          => hiera('cinder::backend::netapp::netapp_webservice_path', undef),
      nas_secure_file_operations      => hiera('cinder::backend::netapp::nas_secure_file_operations', undef),
      nas_secure_file_permissions     => hiera('cinder::backend::netapp::nas_secure_file_permissions', undef),
      netapp_pool_name_search_pattern => hiera('cinder::backend::netapp::netapp_pool_name_search_pattern',
                                                $netapp_pool_name_search_pattern_fallback),
    }
  }

}
