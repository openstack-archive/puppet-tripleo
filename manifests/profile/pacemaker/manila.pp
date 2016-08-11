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
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*manila_cephfsnative_enable*]
#   (Optional) Enable the CephFS Native backend.
#   Defaults to hiera('manila_cephfsnative_enable_backend', 'false')
#
# [*cephfs_handles_share_servers*]
#   (Optional)
#   Defaults to hiera('manila::backend::cephfsnative::driver_handles_share_servers', false)
#
# [*cephfs_backend_name*]
#   (Optional)
#   Defaults to hiera('manila::backend::cephfsnative::cephfs_backend_name')
#
# [*cephfs_conf_path*]
#   (Optional)
#   Defaults to hiera('manila::backend::cephfsnative::cephfs_conf_path')
#
# [*cephfs_auth_id*]
#   (Optional)
#   Defaults to hiera('manila::backend::cephfsnative::cephfs_auth_id')
#
# [*cephfs_cluster_name*]
#   (Optional)
#   Defaults to hiera('manila::backend::cephfsnative::cephfs_cluster_name')
#
# [*cephfs_enable_snapshots*]
#   (Optional)
#   Defaults to hiera('manila::backend::cephfsnative::cephfs_enable_snapshots')
#
class tripleo::profile::pacemaker::manila (
  $bootstrap_node                   = hiera('bootstrap_nodeid'),
  $step                             = hiera('step'),
  $manila_cephfsnative_enable       = hiera('manila::backend::cephfsnative::enable_backend', false),
  $cephfs_handles_share_servers     = hiera('manila::backend::cephfsnative::driver_handles_share_servers'),
  $cephfs_backend_name              = hiera('manila::backend::cephfsnative::cephfs_backend_name'),
  $cephfs_conf_path                 = hiera('manila::backend::cephfsnative::cephfs_conf_path'),
  $cephfs_auth_id                   = hiera('manila::backend::cephfsnative::cephfs_auth_id'),
  $cephfs_cluster_name              = hiera('manila::backend::cephfsnative::cephfs_cluster_name'),
  $cephfs_enable_snapshots          = hiera('manila::backend::cephfsnative::cephfs_enable_snapshots'),
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

  if $step >= 4 {
    include ::tripleo::profile::base::manila::api
    include ::tripleo::profile::base::manila::scheduler
    include ::tripleo::profile::base::manila::share

    # manila generic:
    $manila_generic_enable = hiera('manila_generic_enable_backend', false)
    if $manila_generic_enable {
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
    if $manila_cephfsnative_enable {
      $manila_cephfsnative_backend = hiera('manila::backend::cephfsnative::title')
      manila::backend::cephfsnative { $manila_cephfsnative_backend :
        driver_handles_share_servers => $cephfs_handles_share_servers,
        cephfs_backend_name          => $cephfs_backend_name,
        cephfs_conf_path             => $cephfs_conf_path,
        cephfs_auth_id               => $cephfs_auth_id,
        cephfs_cluster_name          => $cephfs_cluster_name,
        cephfs_enable_snapshots      => $cephfs_enable_snapshots,
      }
    }

    # manila netapp:
    $manila_netapp_enable = hiera('manila_netapp_enable_backend', false)
    if $manila_netapp_enable {
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

    $manila_enabled_backends = delete_undef_values(
      [
        $manila_generic_backend,
        $manila_cephfsnative_backend,
        $manila_netapp_backend
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
    pacemaker::resource::service { $::manila::params::share_service : }

  }
}
