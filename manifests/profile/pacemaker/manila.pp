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
# == Class: tripleo::profile::pacemaker::manila
#
# Manila Pacemaker HA profile for tripleo
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
# [*backend_cephfs_enabled*]
#   (Optional) Whether or not the cephfs backend is enabled
#   Defaults to hiera('manila_backend_cephfs_enabled', false)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('manila_share_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
class tripleo::profile::pacemaker::manila (
  $backend_generic_enabled = hiera('manila_backend_generic_enabled', false),
  $backend_netapp_enabled  = hiera('manila_backend_netapp_enabled', false),
  $backend_vmax_enabled    = hiera('manila_backend_vmax_enabled', false),
  $backend_cephfs_enabled  = hiera('manila_backend_cephfs_enabled', false),
  $bootstrap_node          = hiera('manila_share_short_bootstrap_node_name'),
  $step                    = Integer(hiera('step')),
  $pcs_tries               = hiera('pcs_tries', 20),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  # make it so puppet can't restart the manila-share service, since that is
  # the only pacemaker managed one
  Service <| tag == 'manila-share' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  include ::tripleo::profile::base::manila::share

  if $step >= 2 {
    pacemaker::property { 'manila-share-role-node-property':
      property => 'manila-share-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
  }

  if $step >= 4 {
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

    # manila cephfsnative:
    if $backend_cephfs_enabled {
      $manila_cephfsnative_backend = hiera('manila::backend::cephfsnative::title')
      $cephfs_auth_id = hiera('manila::backend::cephfsnative::cephfs_auth_id')
      $keyring_path = "/etc/ceph/ceph.client.${cephfs_auth_id}.keyring"

      manila::backend::cephfsnative { $manila_cephfsnative_backend :
        driver_handles_share_servers => hiera('manila::backend::cephfsnative::driver_handles_share_servers', false),
        share_backend_name           => hiera('manila::backend::cephfsnative::share_backend_name'),
        cephfs_conf_path             => hiera('manila::backend::cephfsnative::cephfs_conf_path'),
        cephfs_auth_id               => $cephfs_auth_id,
        cephfs_cluster_name          => hiera('manila::backend::cephfsnative::cephfs_cluster_name'),
        cephfs_enable_snapshots      => hiera('manila::backend::cephfsnative::cephfs_enable_snapshots'),
      }

      ceph_config {
        "client.${cephfs_auth_id}/keyring": value => $keyring_path;
        "client.${cephfs_auth_id}/client mount uid": value => 0;
        "client.${cephfs_auth_id}/client mount gid": value => 0;
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
        share_backend_name           => hiera('manila::backend::dellemc_vmax::share_backend_name'),
        vmax_server_container        => hiera('manila::backend::dellemc_vmax::vmax_server_container'),
        vmax_share_data_pools        => hiera('manila::backend::dellemc_vmax::vmax_share_data_pools'),
        vmax_ethernet_ports          => hiera('manila::backend::dellemc_vmax::vmax_ethernet_ports'),
      }
    }



    $manila_enabled_backends = delete_undef_values(
      [
        $manila_generic_backend,
        $manila_cephfsnative_backend,
        $manila_netapp_backend,
        $manila_vmax_backend
      ]
    )
    class { '::manila::backends' :
      enabled_share_backends => $manila_enabled_backends,
    }

    if $pacemaker_master and hiera('stack_action') == 'UPDATE' {
      Manila_api_paste_ini<||> ~> Tripleo::Pacemaker::Resource_restart_flag["${::manila::params::share_service}"]
      Manila_config<||> ~> Tripleo::Pacemaker::Resource_restart_flag["${::manila::params::share_service}"]
      tripleo::pacemaker::resource_restart_flag { "${::manila::params::share_service}": }
    }
  }

  if $step >= 5 and $pacemaker_master {

    # only manila-share is pacemaker managed, and in a/p
    pacemaker::resource::service { $::manila::params::share_service :
      op_params     => 'start timeout=200s stop timeout=200s',
      tries         => $pcs_tries,
      location_rule => {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['manila-share-role eq true'],
      },
    }

  }
}
