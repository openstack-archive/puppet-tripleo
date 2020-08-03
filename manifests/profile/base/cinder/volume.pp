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
# == Class: tripleo::profile::base::cinder::volume
#
# Cinder Volume profile for tripleo
#
# === Parameters
#
# [*cinder_enable_pure_backend*]
#   (Optional) Whether to enable the pure backend
#   Defaults to false
#
# [*cinder_enable_dellsc_backend*]
#   (Optional) Whether to enable the delsc backend
#   Defaults to false
#
# [*cinder_enable_dellemc_sc_backend*]
#   (Optional) Whether to enable the sc backend
#   Defaults to false
#
# [*cinder_enable_dellemc_unity_backend*]
#   (Optional) Whether to enable the unity backend
#   Defaults to false
#
# [*cinder_enable_dellemc_powermax_backend*]
#   (Optional) Whether to enable the powermax backend
#   Defaults to false
#
# [*cinder_enable_dellemc_vmax_iscsi_backend*]
#   (Optional) Whether to enable the vmax iscsi backend
#   Defaults to false
#
# [*cinder_enable_dellemc_vnx_backend*]
#   (Optional) Whether to enable the vnx backend
#   Defaults to false
#
# [*cinder_enable_dellemc_vxflexos_backend*]
#   (Optional) Whether to enable the vxflexos backend
#   Defaults to false
#
# [*cinder_enable_dellemc_xtremio_backend*]
#   (Optional) Whether to enable the xtremio backend
#   Defaults to false
#
# [*cinder_enable_dellemc_xtremio_iscsi_backend*]
#   (Optional) Whether to enable the extremio iscsi backend
#   Defaults to false
#
# [*cinder_enable_hpelefthand_backend*]
#   (Optional) Whether to enable the hpelefthand backend
#   Defaults to false
#
# [*cinder_enable_dellps_backend*]
#   (Optional) Whether to enable the dellps backend
#   Defaults to false
#
# [*cinder_enable_iscsi_backend*]
#   (Optional) Whether to enable the iscsi backend
#   Defaults to true
#
# [*cinder_enable_netapp_backend*]
#   (Optional) Whether to enable the netapp backend
#   Defaults to false
#
# [*cinder_enable_nfs_backend*]
#   (Optional) Whether to enable the nfs backend
#   Defaults to false
#
# [*cinder_enable_rbd_backend*]
#   (Optional) Whether to enable the rbd backend
#   Defaults to false
#
# [*cinder_enable_scaleio_backend*]
#   (Optional) Whether to enable the scaleio backend
#   Defaults to false
#
#[*cinder_enable_vrts_hs_backend*]
#   (Optional) Whether to enable the Veritas HyperScale backend
#   Defaults to false
#
#[*cinder_enable_nvmeof_backend*]
#   (Optional) Whether to enable the NVMeOF backend
#   Defaults to false
#
# [*cinder_user_enabled_backends*]
#   (Optional) List of additional backend stanzas to activate
#   Defaults to hiera('cinder_user_enabled_backends')
#
# [*cinder_rbd_client_name*]
#   (Optional) Name of RBD client
#   Defaults to hiera('tripleo::profile::base::cinder::volume::rbd::cinder_rbd_user_name')
#
# [*cinder_volume_cluster*]
#   (Optional) Name of the cluster when running in active-active mode
#   Defaults to hiera('tripleo::profile::base::cinder::volume::cinder_volume_cluster')
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not
#   Defaults to hiera('enable_internal_tls', false)
#
# [*etcd_certificate_specs*]
#   (optional) TLS certificate specs for the etcd service
#   Defaults to hiera('tripleo::profile::base::etcd::certificate_specs', {})
#
# [*etcd_enabled*]
#   (optional) Whether the etcd service is enabled or not
#   Defaults to hiera('etcd_enabled', false)
#
# [*etcd_host*]
#   (optional) IP address (VIP) of the etcd service
#   Defaults to hiera('etcd_vip', undef)
#
# [*etcd_port*]
#   (optional) Port used by the etcd service
#   Defaults to hiera('tripleo::profile::base::etcd::client_port', '2379')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume (
  $cinder_enable_pure_backend                  = false,
  $cinder_enable_dellsc_backend                = false,
  $cinder_enable_dellemc_sc_backend            = false,
  $cinder_enable_dellemc_unity_backend         = false,
  $cinder_enable_dellemc_powermax_backend      = false,
  $cinder_enable_dellemc_vmax_iscsi_backend    = false,
  $cinder_enable_dellemc_vnx_backend           = false,
  $cinder_enable_dellemc_vxflexos_backend      = false,
  $cinder_enable_dellemc_xtremio_backend       = false,
  $cinder_enable_dellemc_xtremio_iscsi_backend = false,
  $cinder_enable_hpelefthand_backend           = false,
  $cinder_enable_dellps_backend                = false,
  $cinder_enable_iscsi_backend                 = true,
  $cinder_enable_netapp_backend                = false,
  $cinder_enable_nfs_backend                   = false,
  $cinder_enable_rbd_backend                   = false,
  $cinder_enable_scaleio_backend               = false,
  $cinder_enable_vrts_hs_backend               = false,
  $cinder_enable_nvmeof_backend                = false,
  $cinder_user_enabled_backends                = hiera('cinder_user_enabled_backends', undef),
  $cinder_rbd_client_name                      = hiera('tripleo::profile::base::cinder::volume::rbd::cinder_rbd_user_name','openstack'),
  $cinder_volume_cluster                       = hiera('tripleo::profile::base::cinder::volume::cinder_volume_cluster', ''),
  $enable_internal_tls                         = hiera('enable_internal_tls', false),
  $etcd_certificate_specs                      = hiera('tripleo::profile::base::etcd::certificate_specs', {}),
  $etcd_enabled                                = hiera('etcd_enabled', false),
  $etcd_host                                   = hiera('etcd_vip', undef),
  $etcd_port                                   = hiera('tripleo::profile::base::etcd::client_port', '2379'),
  $step                                        = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder

  if $step >= 4 {
    if $cinder_volume_cluster == '' {
      $cinder_volume_cluster_real = undef
    } else {
      $cinder_volume_cluster_real = $cinder_volume_cluster
    }

    if $cinder_volume_cluster_real {
      unless $etcd_enabled {
        fail('Running cinder-volume in active-active mode with a cluster name requires the etcd service.')
      }
      if empty($etcd_host) {
        fail('etcd_vip not set in hieradata')
      }
      if $enable_internal_tls {
        $protocol = 'https'
        $tls_keyfile = $etcd_certificate_specs['service_key']
        $tls_certfile = $etcd_certificate_specs['service_certificate']
        $options = sprintf('?cert_key=%s&cert_cert=%s', $tls_keyfile, $tls_certfile)
      } else {
        $protocol = 'http'
        $options = ''
      }
      $backend_url = sprintf('etcd3+%s://%s:%s%s', $protocol, normalize_ip_for_uri($etcd_host), $etcd_port, $options)
      class { '::cinder::coordination' :
        backend_url => $backend_url,
      }
    }

    class { '::cinder::volume' :
      cluster => $cinder_volume_cluster_real,
    }

    if $cinder_enable_pure_backend {
      include ::tripleo::profile::base::cinder::volume::pure
      $cinder_pure_backend_name = hiera('cinder::backend::pure::volume_backend_name', 'tripleo_pure')
    } else {
      $cinder_pure_backend_name = undef
    }

    if $cinder_enable_dellsc_backend {
      include ::tripleo::profile::base::cinder::volume::dellsc
      $cinder_dellsc_backend_name = hiera('cinder::backend::dellsc_iscsi::volume_backend_name', 'tripleo_dellsc')
    } else {
      $cinder_dellsc_backend_name = undef
    }

    if $cinder_enable_dellemc_sc_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_sc
      $cinder_dellemc_sc_backend_name = hiera('cinder::backend::dellemc_sc::volume_backend_name', 'tripleo_dellemc_sc')
    } else {
      $cinder_dellemc_sc_backend_name = undef
    }

    if $cinder_enable_dellemc_unity_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_unity
      $cinder_dellemc_unity_backend_name = hiera('cinder::backend::dellemc_unity::volume_backend_name', 'tripleo_dellemc_unity')
    } else {
      $cinder_dellemc_unity_backend_name = undef
    }

    if $cinder_enable_dellemc_powermax_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_powermax
      $cinder_dellemc_powermax_backend_name = hiera('cinder::backend::dellemc_powermax::volume_backend_name', 'tripleo_dellemc_powermax')
    } else {
      $cinder_dellemc_powermax_backend_name = undef
    }

    if $cinder_enable_dellemc_vmax_iscsi_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_vmax_iscsi
      $cinder_dellemc_vmax_iscsi_backend_name = hiera('cinder::backend::dellemc_vmax_iscsi::volume_backend_name',
          'tripleo_dellemc_vmax_iscsi')
    } else {
      $cinder_dellemc_vmax_iscsi_backend_name = undef
    }

    if $cinder_enable_dellemc_vnx_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_vnx
      $cinder_dellemc_vnx_backend_name = hiera('cinder::backend::emc_vnx::volume_backend_name',
          'tripleo_dellemc_vnx')
    } else {
      $cinder_dellemc_vnx_backend_name = undef
    }

    if $cinder_enable_dellemc_vxflexos_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_vxflexos
      $cinder_dellemc_vxflexos_backend_name = hiera('cinder::backend::dellemc_vxflexos::volume_backend_name',
          'tripleo_dellemc_vxflexos')
    } else {
      $cinder_dellemc_vxflexos_backend_name = undef
    }

    if $cinder_enable_dellemc_xtremio_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_xtremio
      $cinder_dellemc_xtremio_backend_name = hiera('cinder::backend::dellemc_xtremio::volume_backend_name',
          'tripleo_dellemc_xtremio')
    } else {
      $cinder_dellemc_xtremio_backend_name = undef
    }

    if $cinder_enable_dellemc_xtremio_iscsi_backend {
      include ::tripleo::profile::base::cinder::volume::dellemc_xtremio_iscsi
      $cinder_dellemc_xtreamio_iscsi_backend_name = hiera('cinder::backend::dellemc_extremio_iscsi::volume_backend_name',
          'tripleo_dellemc_xtremio_iscsi')
    } else {
      $cinder_dellemc_xtremio_iscsi_backend_name = undef
    }

    if $cinder_enable_hpelefthand_backend {
      include ::tripleo::profile::base::cinder::volume::hpelefthand
      $cinder_hpelefthand_backend_name = hiera('cinder::backend::hpelefthand_iscsi::volume_backend_name', 'tripleo_hpelefthand')
    } else {
      $cinder_hpelefthand_backend_name = undef
    }

    if $cinder_enable_dellps_backend {
      include ::tripleo::profile::base::cinder::volume::dellps
      $cinder_dellps_backend_name = hiera('cinder::backend::dellps::volume_backend_name', 'tripleo_dellps')
    } else {
      $cinder_dellps_backend_name = undef
    }

    if $cinder_enable_iscsi_backend {
      include ::tripleo::profile::base::cinder::volume::iscsi
      $cinder_iscsi_backend_name = hiera('cinder::backend::iscsi::volume_backend_name', 'tripleo_iscsi')
    } else {
      $cinder_iscsi_backend_name = undef
    }

    if $cinder_enable_netapp_backend {
      include ::tripleo::profile::base::cinder::volume::netapp
      $cinder_netapp_backend_name = hiera('cinder::backend::netapp::volume_backend_name', 'tripleo_netapp')
    } else {
      $cinder_netapp_backend_name = undef
    }

    if $cinder_enable_nfs_backend {
      include ::tripleo::profile::base::cinder::volume::nfs
      $cinder_nfs_backend_name = hiera('cinder::backend::nfs::volume_backend_name', 'tripleo_nfs')
    } else {
      $cinder_nfs_backend_name = undef
    }

    if $cinder_enable_rbd_backend {
      include ::tripleo::profile::base::cinder::volume::rbd
      $cinder_rbd_backend_name = hiera('cinder::backend::rbd::volume_backend_name', 'tripleo_ceph')

      exec{ "exec-setfacl-${cinder_rbd_client_name}-cinder":
        path    => ['/bin', '/usr/bin'],
        command => "setfacl -m u:cinder:r-- /etc/ceph/ceph.client.${cinder_rbd_client_name}.keyring",
        unless  => "getfacl /etc/ceph/ceph.client.${cinder_rbd_client_name}.keyring | grep -q user:cinder:r--",
      }
      -> exec{ "exec-setfacl-${cinder_rbd_client_name}-cinder-mask":
        path    => ['/bin', '/usr/bin'],
        command => "setfacl -m m::r /etc/ceph/ceph.client.${cinder_rbd_client_name}.keyring",
        unless  => "getfacl /etc/ceph/ceph.client.${cinder_rbd_client_name}.keyring | grep -q mask::r",
      }

      $cinder_rbd_extra_pools = hiera('tripleo::profile::base::cinder::volume::rbd::cinder_rbd_extra_pools', undef)
      if $cinder_rbd_extra_pools {
          $base_name = $cinder_rbd_backend_name
          $cinder_rbd_extra_backend_names = $cinder_rbd_extra_pools.map |$pool_name| { "${base_name}_${pool_name}" }
      } else {
          $cinder_rbd_extra_backend_names = undef
      }
    } else {
      $cinder_rbd_backend_name = undef
      $cinder_rbd_extra_backend_names = undef
    }

    if $cinder_enable_scaleio_backend {
      include ::tripleo::profile::base::cinder::volume::scaleio
      $cinder_scaleio_backend_name = hiera('cinder::backend::scaleio::volume_backend_name', 'tripleo_scaleio')
    } else {
      $cinder_scaleio_backend_name = undef
    }

    if $cinder_enable_vrts_hs_backend {
      include ::tripleo::profile::base::cinder::volume::veritas_hyperscale
      $cinder_veritas_hyperscale_backend_name = 'Veritas_HyperScale'
    } else {
      $cinder_veritas_hyperscale_backend_name = undef
    }

    if $cinder_enable_nvmeof_backend {
      include ::tripleo::profile::base::cinder::volume::nvmeof
      $cinder_nvmeof_backend_name = hiera('cinder::backend::nvmeof::volume_backend_name', 'tripleo_nvmeof')
    } else {
      $cinder_nvmeof_backend_name = undef
    }

    $backends = delete_undef_values(concat([], $cinder_iscsi_backend_name,
                                      $cinder_rbd_backend_name,
                                      $cinder_rbd_extra_backend_names,
                                      $cinder_pure_backend_name,
                                      $cinder_dellps_backend_name,
                                      $cinder_dellsc_backend_name,
                                      $cinder_dellemc_sc_backend_name,
                                      $cinder_dellemc_unity_backend_name,
                                      $cinder_dellemc_powermax_backend_name,
                                      $cinder_dellemc_vmax_iscsi_backend_name,
                                      $cinder_dellemc_vnx_backend_name,
                                      $cinder_dellemc_vxflexos_backend_name,
                                      $cinder_dellemc_xtremio_backend_name,
                                      $cinder_dellemc_xtremio_iscsi_backend_name,
                                      $cinder_hpelefthand_backend_name,
                                      $cinder_netapp_backend_name,
                                      $cinder_nfs_backend_name,
                                      $cinder_scaleio_backend_name,
                                      $cinder_veritas_hyperscale_backend_name,
                                      $cinder_user_enabled_backends,
                                      $cinder_nvmeof_backend_name))
    # NOTE(aschultz): during testing it was found that puppet 3 may incorrectly
    # include a "" in the previous array which is not removed by the
    # delete_undef_values function. So we need to make sure we don't have any
    # "" strings in our array.
    $cinder_enabled_backends = delete($backends, '')

    class { '::cinder::backends' :
      enabled_backends => $cinder_enabled_backends,
    }
  }

}
