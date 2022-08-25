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
#   Defaults to lookup('manila_backend_generic_enabled', undef, undef, false)
#
# [*backend_netapp_enabled*]
#   (Optional) Whether or not the netapp backend is enabled
#   Defaults to lookup('manila_backend_netapp_enabled', undef, undef, false)
#
# [*backend_powermax_enabled*]
#   (Optional) Whether or not the powermax backend is enabled
#   Defaults to lookup('manila_backend_powermax_enabled', undef, undef, false)
#
# [*backend_isilon_enabled*]
#   (Optional) Whether or not the isilon backend is enabled
#   Defaults to lookup('manila_backend_isilon_enabled', undef, undef, false)
#
# [*backend_unity_enabled*]
#   (Optional) Whether or not the unity backend is enabled
#   Defaults to lookup('manila_backend_unity_enabled', undef, undef, false)
#
# [*backend_vnx_enabled*]
#   (Optional) Whether or not the vnx backend is enabled
#   Defaults to lookup('manila_backend_vnx_enabled', undef, undef, false)
#
# [*backend_flashblade_enabled*]
#   (Optional) Whether or not the flashblade backend is enabled
#   Defaults to lookup('manila_backend_flashblade_enabled', undef, undef, false)
#
# [*backend_cephfs_enabled*]
#   (Optional) Whether or not the cephfs backend is enabled
#   Defaults to lookup('manila_backend_cephfs_enabled', undef, undef, false)
#
# [*manila_user_enabled_backends*]
#   (Optional) List of additional backend stanzas to activate
#   Defaults to lookup('manila_user_enabled_backends', undef, undef, undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::manila::share (
  $backend_generic_enabled      = lookup('manila_backend_generic_enabled', undef, undef, false),
  $backend_netapp_enabled       = lookup('manila_backend_netapp_enabled', undef, undef, false),
  $backend_powermax_enabled     = lookup('manila_backend_powermax_enabled', undef, undef, false),
  $backend_isilon_enabled       = lookup('manila_backend_isilon_enabled', undef, undef, false),
  $backend_unity_enabled        = lookup('manila_backend_unity_enabled', undef, undef, false),
  $backend_vnx_enabled          = lookup('manila_backend_vnx_enabled', undef, undef, false),
  $backend_flashblade_enabled   = lookup('manila_backend_flashblade_enabled', undef, undef, false),
  $backend_cephfs_enabled       = lookup('manila_backend_cephfs_enabled', undef, undef, false),
  $manila_user_enabled_backends = lookup('manila_user_enabled_backends', undef, undef, undef),
  $step = Integer(lookup('step')),
) {
  include tripleo::profile::base::manila

  if $step >= 4 {
    include manila::share

    # manila generic:
    if $backend_generic_enabled {
      $manila_generic_backend = lookup('manila::backend::generic::title')
      create_resources('manila::backend::generic', { $manila_generic_backend => delete_undef_values({
        'driver_handles_share_servers'     => lookup('manila::backend::generic::driver_handles_share_servers', undef, undef, true),
        'backend_availability_zone'        => lookup('manila::backend::generic::backend_availability_zone', undef, undef, undef),
        'max_time_to_attach'               => lookup('manila::backend::generic::max_time_to_attach', undef, undef, undef),
        'max_time_to_create_volume'        => lookup('manila::backend::generic::max_time_to_create_volume', undef, undef, undef),
        'service_instance_smb_config_path' => lookup('manila::backend::generic::service_instance_smb_config_path', undef, undef, undef),
        'share_mount_path'                 => lookup('manila::backend::generic::share_mount_path', undef, undef, undef),
        'share_volume_fstype'              => lookup('manila::backend::generic::share_volume_fstype', undef, undef, undef),
        'smb_template_config_path'         => lookup('manila::backend::generic::smb_template_config_path', undef, undef, undef),
        'volume_name_template'             => lookup('manila::backend::generic::volume_name_template', undef, undef, undef),
        'volume_snapshot_name_template'    => lookup('manila::backend::generic::volume_snapshot_name_template', undef, undef, undef),
        'cinder_volume_type'               => lookup('manila::backend::generic::cinder_volume_type', undef, undef, undef),
      })})

      $service_instance_user = lookup('manila::service_instance::service_instance_user')
      $service_instance_password = lookup('manila::service_instance::service_instance_password')
      $service_instance_flavor_id = lookup('manila::service_instance::service_instance_flavor_id')
      manila_config {
        "${manila_generic_backend}/service_instance_user":      value => $service_instance_user;
        "${manila_generic_backend}/service_instance_password":  value => $service_instance_password;
        "${manila_generic_backend}/service_instance_flavor_id": value => $service_instance_flavor_id;
      }

      include manila::volume::cinder
    }

    # manila cephfs:
    if $backend_cephfs_enabled {
      $manila_cephfs_backend = lookup('manila::backend::cephfs::title')
      $cephfs_auth_id = lookup('manila::backend::cephfs::cephfs_auth_id')
      $cephfs_ganesha_server_ip = lookup('manila::backend::cephfs::cephfs_ganesha_server_ip', undef, undef, undef)
      $manila_cephfs_protocol_helper_type = lookup('manila::backend::cephfs::cephfs_protocol_helper_type', undef, undef, false)
      $manila_cephfs_pool_name = lookup('manila::backend::cephfs::pool_name', undef, undef, 'manila_data')

      if $cephfs_ganesha_server_ip == undef {
        $cephfs_ganesha_server_ip_real = lookup('ganesha_vip', undef, undef, undef)
      } else {
        $cephfs_ganesha_server_ip_real = $cephfs_ganesha_server_ip
      }

      create_resources('manila::backend::cephfs', { $manila_cephfs_backend => delete_undef_values({
        'driver_handles_share_servers'       => lookup('manila::backend::cephfs::driver_handles_share_servers', undef, undef, false),
        'backend_availability_zone'          => lookup('manila::backend::cephfs::backend_availability_zone', undef, undef, undef),
        'share_backend_name'                 => lookup('manila::backend::cephfs::share_backend_name', undef, undef, undef),
        'cephfs_conf_path'                   => lookup('manila::backend::cephfs::cephfs_conf_path', undef, undef, undef),
        'cephfs_auth_id'                     => $cephfs_auth_id,
        'cephfs_cluster_name'                => lookup('manila::backend::cephfs::cephfs_cluster_name', undef, undef, undef),
        'cephfs_volume_mode'                 => lookup('manila::backend::cephfs::cephfs_volume_mode', undef, undef, '0755'),
        'cephfs_protocol_helper_type'        => $manila_cephfs_protocol_helper_type,
        'cephfs_ganesha_server_ip'           => $cephfs_ganesha_server_ip_real,
        'cephfs_ganesha_server_is_remote'    => lookup('manila::backend::cephfs::cephfs_ganesha_server_is_remote', undef, undef, false),
        'cephfs_ganesha_server_username'     => lookup('manila::backend::cephfs::cephfs_ganesha_server_username', undef, undef, undef),
        'cephfs_ganesha_server_password'     => lookup('manila::backend::cephfs::cephfs_ganesha_server_password', undef, undef, undef),
        'cephfs_ganesha_path_to_private_key' => lookup('manila::backend::cephfs::cephfs_ganesha_path_to_private_key', undef, undef, undef),
      })})

      # cephfs supports both direct cephfs access or access through
      # nfs-ganesha depending whether 'cephfs_protocol_helper_type' is
      # set to 'CEPHFS' or 'NFS'
      if $manila_cephfs_protocol_helper_type == 'NFS' {
        manila::backend::ganesha { $manila_cephfs_backend :
          ganesha_rados_store_enable    => true,
          ganesha_rados_store_pool_name => $manila_cephfs_pool_name,
        }
      }
    }

    # manila netapp:
    if $backend_netapp_enabled {
      $manila_netapp_backend = lookup('manila::backend::netapp::title')
      create_resources('manila::backend::netapp', { $manila_netapp_backend => delete_undef_values({
        'driver_handles_share_servers'         => lookup('manila::backend::netapp::driver_handles_share_servers', undef, undef, true),
        'backend_availability_zone'            => lookup('manila::backend::netapp::backend_availability_zone', undef, undef, undef),
        'netapp_login'                         => lookup('manila::backend::netapp::netapp_login', undef, undef, undef),
        'netapp_password'                      => lookup('manila::backend::netapp::netapp_password', undef, undef, undef),
        'netapp_server_hostname'               => lookup('manila::backend::netapp::netapp_server_hostname', undef, undef, undef),
        'netapp_transport_type'                => lookup('manila::backend::netapp::netapp_transport_type', undef, undef, undef),
        'netapp_storage_family'                => lookup('manila::backend::netapp::netapp_storage_family', undef, undef, undef),
        'netapp_server_port'                   => lookup('manila::backend::netapp::netapp_server_port', undef, undef, undef),
        'netapp_volume_name_template'          => lookup('manila::backend::netapp::netapp_volume_name_template', undef, undef, undef),
        'netapp_vserver'                       => lookup('manila::backend::netapp::netapp_vserver', undef, undef, undef),
        'netapp_vserver_name_template'         => lookup('manila::backend::netapp::netapp_vserver_name_template', undef, undef, undef),
        'netapp_lif_name_template'             => lookup('manila::backend::netapp::netapp_lif_name_template', undef, undef, undef),
        'netapp_aggregate_name_search_pattern' => lookup('manila::backend::netapp::netapp_aggregate_name_search_pattern',
                                                        undef, undef, undef),
        'netapp_root_volume_aggregate'         => lookup('manila::backend::netapp::netapp_root_volume_aggregate', undef, undef, undef),
        'netapp_root_volume'                   => lookup('manila::backend::netapp::netapp_root_volume', undef, undef, undef),
        'netapp_port_name_search_pattern'      => lookup('manila::backend::netapp::netapp_port_name_search_pattern', undef, undef, undef),
        'netapp_trace_flags'                   => lookup('manila::backend::netapp::netapp_trace_flags', undef, undef, undef),
      })})
    }

    # manila powermax:
    if $backend_powermax_enabled {
      $manila_powermax_backend = lookup('manila::backend::dellemc_powermax::title')
      create_resources('manila::backend::dellemc_powermax', { $manila_powermax_backend => delete_undef_values({
        'backend_availability_zone'    => lookup('manila::backend::dellemc_powermax::backend_availability_zone', undef, undef, undef),
        'emc_nas_login'                => lookup('manila::backend::dellemc_powermax::emc_nas_login', undef, undef, undef),
        'emc_nas_password'             => lookup('manila::backend::dellemc_powermax::emc_nas_password', undef, undef, undef),
        'emc_nas_server'               => lookup('manila::backend::dellemc_powermax::emc_nas_server', undef, undef, undef),
        'emc_share_backend'            => lookup('manila::backend::dellemc_powermax::emc_share_backend', undef, undef, 'powermax'),
        'emc_ssl_cert_verify'          => lookup('manila::backend::dellemc_powermax::emc_ssl_cert_verify', undef, undef, false),
        'emc_nas_server_secure'        => lookup('manila::backend::dellemc_powermax::emc_nas_server_secure', undef, undef, false),
        'emc_ssl_cert_path'            => lookup('manila::backend::dellemc_powermax::emc_ssl_cert_path', undef, undef, undef),
        'powermax_server_container'    => lookup('manila::backend::dellemc_powermax::powermax_server_container', undef, undef, undef),
        'powermax_share_data_pools'    => lookup('manila::backend::dellemc_powermax::powermax_share_data_pools', undef, undef, undef),
        'powermax_ethernet_ports'      => lookup('manila::backend::dellemc_powermax::powermax_ethernet_ports', undef, undef, undef),
      })})
    }

    # manila unity:
    if $backend_unity_enabled {
      $manila_unity_backend = lookup('manila::backend::dellemc_unity::title')
      create_resources('manila::backend::dellemc_unity', { $manila_unity_backend => delete_undef_values({
        'driver_handles_share_servers' => lookup('manila::backend::dellemc_unity::driver_handles_share_servers', undef, undef, true),
        'backend_availability_zone'    => lookup('manila::backend::dellemc_unity::backend_availability_zone', undef, undef, undef),
        'emc_nas_login'                => lookup('manila::backend::dellemc_unity::emc_nas_login', undef, undef, undef),
        'emc_nas_password'             => lookup('manila::backend::dellemc_unity::emc_nas_password', undef, undef, undef),
        'emc_nas_server'               => lookup('manila::backend::dellemc_unity::emc_nas_server', undef, undef, undef),
        'emc_share_backend'            => lookup('manila::backend::dellemc_unity::emc_share_backend', undef, undef, 'unity'),
        'unity_server_meta_pool'       => lookup('manila::backend::dellemc_unity::unity_server_meta_pool', undef, undef, undef),
        'unity_share_data_pools'       => lookup('manila::backend::dellemc_unity::unity_share_data_pools', undef, undef, undef),
        'unity_ethernet_ports'         => lookup('manila::backend::dellemc_unity::unity_ethernet_ports', undef, undef, undef),
        'network_plugin_ipv6_enabled'  => lookup('manila::backend::dellemc_unity::network_plugin_ipv6_enabled', undef, undef, undef),
        'emc_ssl_cert_verify'          => lookup('manila::backend::dellemc_unity::emc_ssl_cert_verify', undef, undef, undef),
        'emc_ssl_cert_path'            => lookup('manila::backend::dellemc_unity::emc_ssl_cert_path', undef, undef, undef),
      })})
    }

    # manila vnx:
    if $backend_vnx_enabled {
      $manila_vnx_backend = lookup('manila::backend::dellemc_vnx::title')
      create_resources('manila::backend::dellemc_vnx', { $manila_vnx_backend => delete_undef_values({
        'backend_availability_zone'    => lookup('manila::backend::dellemc_vnx::backend_availability_zone', undef, undef, undef),
        'emc_nas_login'                => lookup('manila::backend::dellemc_vnx::emc_nas_login', undef, undef, undef),
        'emc_nas_password'             => lookup('manila::backend::dellemc_vnx::emc_nas_password', undef, undef, undef),
        'emc_nas_server'               => lookup('manila::backend::dellemc_vnx::emc_nas_server', undef, undef, undef),
        'emc_share_backend'            => lookup('manila::backend::dellemc_vnx::emc_share_backend', undef, undef, 'vnx'),
        'vnx_server_container'         => lookup('manila::backend::dellemc_vnx::vnx_server_container', undef, undef, undef),
        'vnx_share_data_pools'         => lookup('manila::backend::dellemc_vnx::vnx_share_data_pools', undef, undef, undef),
        'vnx_ethernet_ports'           => lookup('manila::backend::dellemc_vnx::vnx_ethernet_ports', undef, undef, undef),
        'network_plugin_ipv6_enabled'  => lookup('manila::backend::dellemc_vnx::network_plugin_ipv6_enabled', undef, undef, undef),
        'emc_ssl_cert_verify'          => lookup('manila::backend::dellemc_vnx::emc_ssl_cert_verify', undef, undef, undef),
        'emc_ssl_cert_path'            => lookup('manila::backend::dellemc_vnx::emc_ssl_cert_path', undef, undef, undef),
      })})
    }

    # manila isilon:
    if $backend_isilon_enabled {
      $manila_isilon_backend = lookup('manila::backend::dellemc_isilon::title')
      create_resources('manila::backend::dellemc_isilon', { $manila_isilon_backend => delete_undef_values({
        'backend_availability_zone'    => lookup('manila::backend::dellemc_isilon::backend_availability_zone', undef, undef, undef),
        'emc_nas_login'                => lookup('manila::backend::dellemc_isilon::emc_nas_login', undef, undef, undef),
        'emc_nas_password'             => lookup('manila::backend::dellemc_isilon::emc_nas_password', undef, undef, undef),
        'emc_nas_server'               => lookup('manila::backend::dellemc_isilon::emc_nas_server', undef, undef, undef),
        'emc_share_backend'            => lookup('manila::backend::dellemc_isilon::emc_share_backend', undef, undef, 'isilon'),
        'emc_nas_root_dir'             => lookup('manila::backend::dellemc_isilon::emc_nas_root_dir', undef, undef, undef),
        'emc_nas_server_port'          => lookup('manila::backend::dellemc_isilon::emc_server_port', undef, undef, undef),
        'emc_nas_server_secure'        => lookup('manila::backend::dellemc_isilon::emc_nas_secure', undef, undef, undef),
      })})
    }

    # manila flashblade:
    if $backend_flashblade_enabled {
      $manila_flashblade_backend = lookup('manila::backend::flashblade::title')
      create_resources('manila::backend::flashblade', { $manila_flashblade_backend => delete_undef_values({
        'flashblade_mgmt_vip'          => lookup('manila::backend::flashblade::flashblade_mgmt_vip', undef, undef, undef),
        'backend_availability_zone'    => lookup('manila::backend::flashblade::backend_availability_zone', undef, undef, undef),
        'flashblade_data_vip'          => lookup('manila::backend::flashblade::flashblade_data_vip', undef, undef, undef),
        'flashblade_api_token'         => lookup('manila::backend::flashblade::flashblade_api_token', undef, undef, undef),
        'flashblade_eradicate'         => lookup('manila::backend::flashblade::flashblade_eradicate', undef, undef, undef),
      })})
    }

    $backends = delete_undef_values(concat([], $manila_generic_backend,
                                      $manila_cephfs_backend,
                                      $manila_netapp_backend,
                                      $manila_powermax_backend,
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
