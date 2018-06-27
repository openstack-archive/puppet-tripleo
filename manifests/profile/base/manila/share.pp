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
# [*backend_cephfs_enabled*]
#   (Optional) Whether or not the cephfs backend is enabled
#   Defaults to hiera('manila_backend_cephfs_enabled', false)
#
# [*backend_vnx_enabled*]
#   (Optional) Whether or not the vnx backend is enabled
#   Defaults to hiera('manila_backend_vnx_enabled', false)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::manila::share (
  $backend_generic_enabled = hiera('manila_backend_generic_enabled', false),
  $backend_netapp_enabled  = hiera('manila_backend_netapp_enabled', false),
  $backend_vmax_enabled    = hiera('manila_backend_vmax_enabled', false),
  $backend_isilon_enabled  = hiera('manila_backend_isilon_enabled', false),
  $backend_unity_enabled   = hiera('manila_backend_unity_enabled', false),
  $backend_vnx_enabled     = hiera('manila_backend_vnx_enabled', false),
  $backend_cephfs_enabled  = hiera('manila_backend_cephfs_enabled', false),
  $step = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::manila

  if $step >= 4 {
    include ::manila::share

    # manila generic:
    if $backend_generic_enabled {
      $manila_generic_backend = hiera('manila::backend::generic::title')
      manila::backend::generic { $manila_generic_backend :
        driver_handles_share_servers     => hiera('manila::backend::generic::driver_handles_share_servers', true),
        max_time_to_attach               => hiera('manila::backend::generic::max_time_to_attach'),
        max_time_to_create_volume        => hiera('manila::backend::generic::max_time_to_create_volume'),
        service_instance_smb_config_path => hiera('manila::backend::generic::service_instance_smb_config_path'),
        share_mount_path                 => hiera('manila::backend::generic::share_mount_path'),
        share_volume_fstype              => hiera('manila::backend::generic::share_volume_fstype'),
        smb_template_config_path         => hiera('manila::backend::generic::smb_template_config_path'),
        volume_name_template             => hiera('manila::backend::generic::volume_name_template'),
        volume_snapshot_name_template    => hiera('manila::backend::generic::volume_snapshot_name_template'),
        cinder_volume_type               => hiera('manila::backend::generic::cinder_volume_type'),
      }

      $service_instance_user = hiera('manila::service_instance::service_instance_user')
      $service_instance_password = hiera('manila::service_instance::service_instance_password')
      $service_instance_flavor_id = hiera('manila::service_instance::service_instance_flavor_id')
      manila_config {
        "${manila_generic_backend}/service_instance_user":      value => $service_instance_user;
        "${manila_generic_backend}/service_instance_password":  value => $service_instance_password;
        "${manila_generic_backend}/service_instance_flavor_id": value => $service_instance_flavor_id;
      }

      include ::manila::volume::cinder
    }

    # manila cephfs:
    if $backend_cephfs_enabled {
      $manila_cephfs_protocol_helper_type = hiera('manila::backend::cephfs::cephfs_protocol_helper_type', false)
      if $manila_cephfs_protocol_helper_type {
        # new manila ceph driver is renamed from 'cephfsnative' to 'cephfs'
        # and supports both direct cephfs access or access through
        # nfs-ganesha depending whether 'cephfs_protocol_helper_type' is
        # set to 'CEPHFS' or 'NFS'
        $manila_cephfs_backend = hiera('manila::backend::cephfs::title')
        $cephfs_auth_id = hiera('manila::backend::cephfs::cephfs_auth_id')
        manila::backend::cephfs { $manila_cephfs_backend :
          driver_handles_share_servers => hiera('manila::backend::cephfs::driver_handles_share_servers', false),
          share_backend_name           => hiera('manila::backend::cephfs::share_backend_name'),
          cephfs_conf_path             => hiera('manila::backend::cephfs::cephfs_conf_path'),
          cephfs_auth_id               => $cephfs_auth_id,
          cephfs_cluster_name          => hiera('manila::backend::cephfs::cephfs_cluster_name'),
          cephfs_enable_snapshots      => hiera('manila::backend::cephfs::cephfs_enable_snapshots'),
          cephfs_protocol_helper_type  => $manila_cephfs_protocol_helper_type,
          cephfs_ganesha_server_ip     => hiera('ganesha_vip', undef),
        }
        if $manila_cephfs_protocol_helper_type == 'NFS' {
          manila_config {
            "${manila_cephfs_backend}/ganesha_rados_store_enable":    value => true;
            "${manila_cephfs_backend}/ganesha_rados_store_pool_name": value => 'manila_data';
          }
        }
      } else {
        # for backward compatibility with older heat templates which used
        # 'cephfsnative' driver
        $manila_cephfsnative_backend = hiera('manila::backend::cephfsnative::title')
        $cephfs_auth_id = hiera('manila::backend::cephfsnative::cephfs_auth_id')
        manila::backend::cephfsnative { $manila_cephfsnative_backend :
          driver_handles_share_servers => hiera('manila::backend::cephfsnative::driver_handles_share_servers', false),
          share_backend_name           => hiera('manila::backend::cephfsnative::share_backend_name'),
          cephfs_conf_path             => hiera('manila::backend::cephfsnative::cephfs_conf_path'),
          cephfs_auth_id               => $cephfs_auth_id,
          cephfs_cluster_name          => hiera('manila::backend::cephfsnative::cephfs_cluster_name'),
          cephfs_enable_snapshots      => hiera('manila::backend::cephfsnative::cephfs_enable_snapshots'),
        }
      }

      $keyring_path = "/etc/ceph/ceph.client.${cephfs_auth_id}.keyring"
      ceph_config {
        "client.${cephfs_auth_id}/keyring": value => $keyring_path;
        "client.${cephfs_auth_id}/client mount uid": value => 0;
        "client.${cephfs_auth_id}/client mount gid": value => 0;
      }

      exec{ "exec-setfacl-${cephfs_auth_id}":
        path    => ['/bin', '/usr/bin' ],
        command => "setfacl -m u:manila:r-- ${keyring_path}",
        unless  => "getfacl ${keyring_path} | grep -q user:manila:r--",
      }
      -> exec{ "exec-setfacl-${cephfs_auth_id}-mask":
        path    => ['/bin', '/usr/bin' ],
        command => "setfacl -m m::r ${keyring_path}",
        unless  => "getfacl ${keyring_path} | grep -q mask::r",
      }
    }

    # manila netapp:
    if $backend_netapp_enabled {
      $manila_netapp_backend = hiera('manila::backend::netapp::title')
      manila::backend::netapp { $manila_netapp_backend :
        driver_handles_share_servers         => hiera('manila::backend::netapp::driver_handles_share_servers', true),
        netapp_login                         => hiera('manila::backend::netapp::netapp_login'),
        netapp_password                      => hiera('manila::backend::netapp::netapp_password'),
        netapp_server_hostname               => hiera('manila::backend::netapp::netapp_server_hostname'),
        netapp_transport_type                => hiera('manila::backend::netapp::netapp_transport_type'),
        netapp_storage_family                => hiera('manila::backend::netapp::netapp_storage_family'),
        netapp_server_port                   => hiera('manila::backend::netapp::netapp_server_port'),
        netapp_volume_name_template          => hiera('manila::backend::netapp::netapp_volume_name_template'),
        netapp_vserver                       => hiera('manila::backend::netapp::netapp_vserver'),
        netapp_vserver_name_template         => hiera('manila::backend::netapp::netapp_vserver_name_template'),
        netapp_lif_name_template             => hiera('manila::backend::netapp::netapp_lif_name_template'),
        netapp_aggregate_name_search_pattern => hiera('manila::backend::netapp::netapp_aggregate_name_search_pattern'),
        netapp_root_volume_aggregate         => hiera('manila::backend::netapp::netapp_root_volume_aggregate'),
        netapp_root_volume_name              => hiera('manila::backend::netapp::netapp_root_volume'),
        netapp_port_name_search_pattern      => hiera('manila::backend::netapp::netapp_port_name_search_pattern'),
        netapp_trace_flags                   => hiera('manila::backend::netapp::netapp_trace_flags'),
      }
    }

    # manila vmax:
    if $backend_vmax_enabled {
      $manila_vmax_backend = hiera('manila::backend::dellemc_vmax::title')
      manila::backend::dellemc_vmax { $manila_vmax_backend :
        driver_handles_share_servers => hiera('manila::backend::dellemc_vmax::driver_handles_share_servers', true),
        emc_nas_login                => hiera('manila::backend::dellemc_vmax::emc_nas_login'),
        emc_nas_password             => hiera('manila::backend::dellemc_vmax::emc_nas_password'),
        emc_nas_server               => hiera('manila::backend::dellemc_vmax::emc_nas_server'),
        emc_share_backend            => hiera('manila::backend::dellemc_vmax::emc_share_backend','vmax'),
        vmax_server_container        => hiera('manila::backend::dellemc_vmax::vmax_server_container'),
        vmax_share_data_pools        => hiera('manila::backend::dellemc_vmax::vmax_share_data_pools'),
        vmax_ethernet_ports          => hiera('manila::backend::dellemc_vmax::vmax_ethernet_ports'),
      }
    }
    # manila unity:
    if $backend_unity_enabled {
      $manila_unity_backend = hiera('manila::backend::dellemc_unity::title')
      manila::backend::dellemc_unity { $manila_unity_backend :
        driver_handles_share_servers => hiera('manila::backend::dellemc_unity::driver_handles_share_servers', true),
        emc_nas_login                => hiera('manila::backend::dellemc_unity::emc_nas_login'),
        emc_nas_password             => hiera('manila::backend::dellemc_unity::emc_nas_password'),
        emc_nas_server               => hiera('manila::backend::dellemc_unity::emc_nas_server'),
        emc_share_backend            => hiera('manila::backend::dellemc_unity::emc_share_backend','unity'),
        unity_server_meta_pool       => hiera('manila::backend::dellemc_unity::unity_server_meta_pool'),
        unity_share_data_pools       => hiera('manila::backend::dellemc_unity::unity_share_data_pools'),
        unity_ethernet_ports         => hiera('manila::backend::dellemc_unity::unity_ethernet_ports'),
      }
    }
    # manila vnx:
    if $backend_vnx_enabled {
      $manila_vnx_backend = hiera('manila::backend::dellemc_vnx::title')
      manila::backend::dellemc_vnx { $manila_vnx_backend :
        driver_handles_share_servers => hiera('manila::backend::dellemc_vnx::driver_handles_share_servers', false),
        emc_nas_login                => hiera('manila::backend::dellemc_vnx::emc_nas_login'),
        emc_nas_password             => hiera('manila::backend::dellemc_vnx::emc_nas_password'),
        emc_nas_server               => hiera('manila::backend::dellemc_vnx::emc_nas_server'),
        emc_share_backend            => hiera('manila::backend::dellemc_vnx::emc_share_backend','vnx'),
        vnx_server_container         => hiera('manila::backend::dellemc_vnx::vnx_server_container'),
        vnx_share_data_pools         => hiera('manila::backend::dellemc_vnx::vnx_share_data_pools'),
        vnx_ethernet_ports           => hiera('manila::backend::dellemc_vnx::vnx_ethernet_ports'),
      }
    }



    # manila isilon:
    if $backend_isilon_enabled {
      $manila_isilon_backend = hiera('manila::backend::dellemc_isilon::title')
      manila::backend::dellemc_isilon { $manila_isilon_backend :
        driver_handles_share_servers => hiera('manila::backend::dellemc_isilon::driver_handles_share_servers', false),
        emc_nas_login                => hiera('manila::backend::dellemc_isilon::emc_nas_login'),
        emc_nas_password             => hiera('manila::backend::dellemc_isilon::emc_nas_password'),
        emc_nas_server               => hiera('manila::backend::dellemc_isilon::emc_nas_server'),
        emc_share_backend            => hiera('manila::backend::dellemc_isilon::emc_share_backend','isilon'),
        emc_nas_root_dir             => hiera('manila::backend::dellemc_isilon::emc_nas_root_dir'),
        emc_nas_server_port          => hiera('manila::backend::dellemc_isilon::emc_server_port'),
        emc_nas_server_secure        => hiera('manila::backend::dellemc_isilon::emc_nas_secure'),
      }
    }

    $manila_enabled_backends = delete_undef_values(
      [
        $manila_generic_backend,
        $manila_cephfsnative_backend,
        $manila_cephfs_backend,
        $manila_netapp_backend,
        $manila_vmax_backend,
        $manila_isilon_backend,
        $manila_unity_backend,
        $manila_vnx_backend
      ]
    )
    class { '::manila::backends' :
      enabled_share_backends => $manila_enabled_backends,
    }
  }
}
