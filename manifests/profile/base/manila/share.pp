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
# == Class: tripleo::profile::base::manila::share
#
# Manila share profile for tripleo
#
# === Parameters
#
# [*backend_generic_enabled*]
#   (Optional) Whether or not the generic backend is enabled
#   Defaults to hiera('manila_backend_generic_enabled', false)
#
# [*backend_netapp_enabled*]
#   (Optional) Whether or not the netapp backend is enabled
#   Defaults to hiera('manila_backend_netapp_enabled', false)
#
# [*backend_vmax_enabled*]
#   (Optional) Whether or not the vmax backend is enabled
#   Defaults to hiera('manila_backend_vmax_enabled', false)
#
# [*backend_isilon_enabled*]
#   (Optional) Whether or not the isilon backend is enabled
#   Defaults to hiera('manila_backend_isilon_enabled', false)
#
# [*backend_unity_enabled*]
#   (Optional) Whether or not the unity backend is enabled
#   Defaults to hiera('manila_backend_unity_enabled', false)
#
# [*backend_vnx_enabled*]
#   (Optional) Whether or not the vnx backend is enabled
#   Defaults to hiera('manila_backend_vnx_enabled', false)
#
# [*backend_flashblade_enabled*]
#   (Optional) Whether or not the flashblade backend is enabled
#   Defaults to hiera('manila_backend_flashblade_enabled', false)
#
# [*backend_cephfs_enabled*]
#   (Optional) Whether or not the cephfs backend is enabled
#   Defaults to hiera('manila_backend_cephfs_enabled', false)
#
# [*manila_user_enabled_backends*]
#   (Optional) List of additional backend stanzas to activate
#   Defaults to hiera('manila_user_enabled_backends', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::manila::share (
  $backend_generic_enabled      = hiera('manila_backend_generic_enabled', false),
  $backend_netapp_enabled       = hiera('manila_backend_netapp_enabled', false),
  $backend_vmax_enabled         = hiera('manila_backend_vmax_enabled', false),
  $backend_isilon_enabled       = hiera('manila_backend_isilon_enabled', false),
  $backend_unity_enabled        = hiera('manila_backend_unity_enabled', false),
  $backend_vnx_enabled          = hiera('manila_backend_vnx_enabled', false),
  $backend_flashblade_enabled   = hiera('manila_backend_flashblade_enabled', false),
  $backend_cephfs_enabled       = hiera('manila_backend_cephfs_enabled', false),
  $manila_user_enabled_backends = hiera('manila_user_enabled_backends', undef),
  $step = Integer(hiera('step')),
) {
  include tripleo::profile::base::manila

  if $step >= 4 {
    include manila::share

    # manila generic:
    if $backend_generic_enabled {
      $manila_generic_backend = hiera('manila::backend::generic::title')
      create_resources('manila::backend::generic', { $manila_generic_backend => delete_undef_values({
        'driver_handles_share_servers'     => hiera('manila::backend::generic::driver_handles_share_servers', true),
        'max_time_to_attach'               => hiera('manila::backend::generic::max_time_to_attach', undef),
        'max_time_to_create_volume'        => hiera('manila::backend::generic::max_time_to_create_volume', undef),
        'service_instance_smb_config_path' => hiera('manila::backend::generic::service_instance_smb_config_path', undef),
        'share_mount_path'                 => hiera('manila::backend::generic::share_mount_path', undef),
        'share_volume_fstype'              => hiera('manila::backend::generic::share_volume_fstype', undef),
        'smb_template_config_path'         => hiera('manila::backend::generic::smb_template_config_path', undef),
        'volume_name_template'             => hiera('manila::backend::generic::volume_name_template', undef),
        'volume_snapshot_name_template'    => hiera('manila::backend::generic::volume_snapshot_name_template', undef),
        'cinder_volume_type'               => hiera('manila::backend::generic::cinder_volume_type', undef),
      })})

      $service_instance_user = hiera('manila::service_instance::service_instance_user')
      $service_instance_password = hiera('manila::service_instance::service_instance_password')
      $service_instance_flavor_id = hiera('manila::service_instance::service_instance_flavor_id')
      manila_config {
        "${manila_generic_backend}/service_instance_user":      value => $service_instance_user;
        "${manila_generic_backend}/service_instance_password":  value => $service_instance_password;
        "${manila_generic_backend}/service_instance_flavor_id": value => $service_instance_flavor_id;
      }

      include manila::volume::cinder
    }

    # manila cephfs:
    if $backend_cephfs_enabled {
      $manila_cephfs_backend = hiera('manila::backend::cephfs::title')
      $cephfs_auth_id = hiera('manila::backend::cephfs::cephfs_auth_id')
      $cephfs_ganesha_server_ip = hiera('manila::backend::cephfs::cephfs_ganesha_server_ip', undef)
      $manila_cephfs_protocol_helper_type = hiera('manila::backend::cephfs::cephfs_protocol_helper_type', false)
      $manila_cephfs_pool_name = hiera('manila::backend::cephfs::pool_name', 'manila_data')
      $manila_cephfs_ceph_conf_path = hiera('manila_cephfs_ceph_conf_path', '/etc/ceph')

      if $cephfs_ganesha_server_ip == undef {
        $cephfs_ganesha_server_ip_real = hiera('ganesha_vip', undef)
      } else {
        $cephfs_ganesha_server_ip_real = $cephfs_ganesha_server_ip
      }

      create_resources('manila::backend::cephfs', { $manila_cephfs_backend => delete_undef_values({
        'driver_handles_share_servers'       => hiera('manila::backend::cephfs::driver_handles_share_servers', false),
        'share_backend_name'                 => hiera('manila::backend::cephfs::share_backend_name', undef),
        'cephfs_conf_path'                   => hiera('manila::backend::cephfs::cephfs_conf_path', undef),
        'cephfs_auth_id'                     => $cephfs_auth_id,
        'cephfs_cluster_name'                => hiera('manila::backend::cephfs::cephfs_cluster_name', undef),
        'cephfs_volume_mode'                 => hiera('manila::backend::cephfs::cephfs_volume_mode', '0755'),
        'cephfs_protocol_helper_type'        => $manila_cephfs_protocol_helper_type,
        'cephfs_ganesha_server_ip'           => $cephfs_ganesha_server_ip_real,
        'cephfs_ganesha_server_is_remote'    => hiera('manila::backend::cephfs::cephfs_ganesha_server_is_remote', false),
        'cephfs_ganesha_server_username'     => hiera('manila::backend::cephfs::cephfs_ganesha_server_username', undef),
        'cephfs_ganesha_server_password'     => hiera('manila::backend::cephfs::cephfs_ganesha_server_password', undef),
        'cephfs_ganesha_path_to_private_key' => hiera('manila::backend::cephfs::cephfs_ganesha_path_to_private_key', undef),
      })})

      # cephfs supports both direct cephfs access or access through
      # nfs-ganesha depending whether 'cephfs_protocol_helper_type' is
      # set to 'CEPHFS' or 'NFS'
      if $manila_cephfs_protocol_helper_type == 'NFS' {
        manila_config {
          "${manila_cephfs_backend}/ganesha_rados_store_enable":    value => true;
          "${manila_cephfs_backend}/ganesha_rados_store_pool_name": value => $manila_cephfs_pool_name;
        }
      }

      $keyring_local_path = "${manila_cephfs_ceph_conf_path}/ceph.client.${cephfs_auth_id}.keyring"
      exec{ "exec-setfacl-${cephfs_auth_id}":
        path    => ['/bin', '/usr/bin' ],
        command => "setfacl -m u:manila:r-- ${keyring_local_path}",
        unless  => "getfacl ${keyring_local_path} | grep -q user:manila:r--",
      }
      -> exec{ "exec-setfacl-${cephfs_auth_id}-mask":
        path    => ['/bin', '/usr/bin' ],
        command => "setfacl -m m::r ${keyring_local_path}",
        unless  => "getfacl ${keyring_local_path} | grep -q mask::r",
      }
    }

    # manila netapp:
    if $backend_netapp_enabled {
      $manila_netapp_backend = hiera('manila::backend::netapp::title')
      create_resources('manila::backend::netapp', { $manila_netapp_backend => delete_undef_values({
        'driver_handles_share_servers'         => hiera('manila::backend::netapp::driver_handles_share_servers', true),
        'netapp_login'                         => hiera('manila::backend::netapp::netapp_login', undef),
        'netapp_password'                      => hiera('manila::backend::netapp::netapp_password', undef),
        'netapp_server_hostname'               => hiera('manila::backend::netapp::netapp_server_hostname', undef),
        'netapp_transport_type'                => hiera('manila::backend::netapp::netapp_transport_type', undef),
        'netapp_storage_family'                => hiera('manila::backend::netapp::netapp_storage_family', undef),
        'netapp_server_port'                   => hiera('manila::backend::netapp::netapp_server_port', undef),
        'netapp_volume_name_template'          => hiera('manila::backend::netapp::netapp_volume_name_template', undef),
        'netapp_vserver'                       => hiera('manila::backend::netapp::netapp_vserver', undef),
        'netapp_vserver_name_template'         => hiera('manila::backend::netapp::netapp_vserver_name_template', undef),
        'netapp_lif_name_template'             => hiera('manila::backend::netapp::netapp_lif_name_template', undef),
        'netapp_aggregate_name_search_pattern' => hiera('manila::backend::netapp::netapp_aggregate_name_search_pattern', undef),
        'netapp_root_volume_aggregate'         => hiera('manila::backend::netapp::netapp_root_volume_aggregate', undef),
        'netapp_root_volume'                   => hiera('manila::backend::netapp::netapp_root_volume', undef),
        'netapp_port_name_search_pattern'      => hiera('manila::backend::netapp::netapp_port_name_search_pattern', undef),
        'netapp_trace_flags'                   => hiera('manila::backend::netapp::netapp_trace_flags', undef),
      })})
    }

    # manila vmax:
    if $backend_vmax_enabled {
      $manila_vmax_backend = hiera('manila::backend::dellemc_vmax::title')
      create_resources('manila::backend::dellemc_vmax', { $manila_vmax_backend => delete_undef_values({
        'emc_nas_login'                => hiera('manila::backend::dellemc_vmax::emc_nas_login', undef),
        'emc_nas_password'             => hiera('manila::backend::dellemc_vmax::emc_nas_password', undef),
        'emc_nas_server'               => hiera('manila::backend::dellemc_vmax::emc_nas_server', undef),
        'emc_share_backend'            => hiera('manila::backend::dellemc_vmax::emc_share_backend','vmax'),
        'vmax_server_container'        => hiera('manila::backend::dellemc_vmax::vmax_server_container', undef),
        'vmax_share_data_pools'        => hiera('manila::backend::dellemc_vmax::vmax_share_data_pools', undef),
        'vmax_ethernet_ports'          => hiera('manila::backend::dellemc_vmax::vmax_ethernet_ports', undef),
      })})
    }

    # manila unity:
    if $backend_unity_enabled {
      $manila_unity_backend = hiera('manila::backend::dellemc_unity::title')
      create_resources('manila::backend::dellemc_unity', { $manila_unity_backend => delete_undef_values({
        'driver_handles_share_servers' => hiera('manila::backend::dellemc_unity::driver_handles_share_servers', true),
        'emc_nas_login'                => hiera('manila::backend::dellemc_unity::emc_nas_login', undef),
        'emc_nas_password'             => hiera('manila::backend::dellemc_unity::emc_nas_password', undef),
        'emc_nas_server'               => hiera('manila::backend::dellemc_unity::emc_nas_server', undef),
        'emc_share_backend'            => hiera('manila::backend::dellemc_unity::emc_share_backend','unity', undef),
        'unity_server_meta_pool'       => hiera('manila::backend::dellemc_unity::unity_server_meta_pool', undef),
        'unity_share_data_pools'       => hiera('manila::backend::dellemc_unity::unity_share_data_pools', undef),
        'unity_ethernet_ports'         => hiera('manila::backend::dellemc_unity::unity_ethernet_ports', undef),
        'network_plugin_ipv6_enabled'  => hiera('manila::backend::dellemc_unity::network_plugin_ipv6_enabled', undef),
        'emc_ssl_cert_verify'          => hiera('manila::backend::dellemc_unity::emc_ssl_cert_verify', undef),
        'emc_ssl_cert_path'            => hiera('manila::backend::dellemc_unity::emc_ssl_cert_path', undef),
      })})
    }

    # manila vnx:
    if $backend_vnx_enabled {
      $manila_vnx_backend = hiera('manila::backend::dellemc_vnx::title')
      create_resources('manila::backend::dellemc_vnx', { $manila_vnx_backend => delete_undef_values({
        'emc_nas_login'                => hiera('manila::backend::dellemc_vnx::emc_nas_login', undef),
        'emc_nas_password'             => hiera('manila::backend::dellemc_vnx::emc_nas_password', undef),
        'emc_nas_server'               => hiera('manila::backend::dellemc_vnx::emc_nas_server', undef),
        'emc_share_backend'            => hiera('manila::backend::dellemc_vnx::emc_share_backend','vnx'),
        'vnx_server_container'         => hiera('manila::backend::dellemc_vnx::vnx_server_container', undef),
        'vnx_share_data_pools'         => hiera('manila::backend::dellemc_vnx::vnx_share_data_pools', undef),
        'vnx_ethernet_ports'           => hiera('manila::backend::dellemc_vnx::vnx_ethernet_ports', undef),
        'network_plugin_ipv6_enabled'  => hiera('manila::backend::dellemc_vnx::network_plugin_ipv6_enabled', undef),
        'emc_ssl_cert_verify'          => hiera('manila::backend::dellemc_vnx::emc_ssl_cert_verify', undef),
        'emc_ssl_cert_path'            => hiera('manila::backend::dellemc_vnx::emc_ssl_cert_path', undef),
      })})
    }

    # manila isilon:
    if $backend_isilon_enabled {
      $manila_isilon_backend = hiera('manila::backend::dellemc_isilon::title')
      create_resources('manila::backend::dellemc_isilon', { $manila_isilon_backend => delete_undef_values({
        'emc_nas_login'                => hiera('manila::backend::dellemc_isilon::emc_nas_login', undef),
        'emc_nas_password'             => hiera('manila::backend::dellemc_isilon::emc_nas_password', undef),
        'emc_nas_server'               => hiera('manila::backend::dellemc_isilon::emc_nas_server', undef),
        'emc_share_backend'            => hiera('manila::backend::dellemc_isilon::emc_share_backend','isilon'),
        'emc_nas_root_dir'             => hiera('manila::backend::dellemc_isilon::emc_nas_root_dir', undef),
        'emc_nas_server_port'          => hiera('manila::backend::dellemc_isilon::emc_server_port', undef),
        'emc_nas_server_secure'        => hiera('manila::backend::dellemc_isilon::emc_nas_secure', undef),
      })})
    }

    # manila flashblade:
    if $backend_flashblade_enabled {
      $manila_flashblade_backend = hiera('manila::backend::flashblade::title')
      create_resources('manila::backend::flashblade', { $manila_flashblade_backend => delete_undef_values({
        'flashblade_mgmt_vip'  => hiera('manila::backend::flashblade::flashblade_mgmt_vip', undef),
        'flashblade_data_vip'  => hiera('manila::backend::flashblade::flashblade_data_vip', undef),
        'flashblade_api_token' => hiera('manila::backend::flashblade::flashblade_api_token', undef),
        'flashblade_eradicate' => hiera('manila::backend::flashblade::flashblade_eradicate', undef),
      })})
    }

    $backends = delete_undef_values(concat([], $manila_generic_backend,
                                      $manila_cephfs_backend,
                                      $manila_netapp_backend,
                                      $manila_vmax_backend,
                                      $manila_isilon_backend,
                                      $manila_unity_backend,
                                      $manila_vnx_backend,
                                      $manila_flashblade_backend,
                                      $manila_user_enabled_backends))
    $manila_enabled_backends = delete($backends, '')

    class { 'manila::backends' :
      enabled_share_backends => $manila_enabled_backends,
    }
  }
}
