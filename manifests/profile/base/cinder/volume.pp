# Copyright 2022 Red Hat, Inc.
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
# [*cinder_enable_dellemc_sc_backend*]
#   (Optional) Whether to enable the sc backend
#   Defaults to false
#
# [*cinder_enable_dellemc_unity_backend*]
#   (Optional) Whether to enable the unity backend
#   Defaults to false
#
# [*cinder_enable_dellemc_powerflex_backend*]
#   (Optional) Whether to enable the powerflex backend
#   Defaults to false
#
# [*cinder_enable_dellemc_powermax_backend*]
#   (Optional) Whether to enable the powermax backend
#   Defaults to false
#
# [*cinder_enable_dellemc_powerstore_backend*]
#   (Optional) Whether to enable the powerstore backend
#   Defaults to false
#
# [*cinder_enable_dellemc_vnx_backend*]
#   (Optional) Whether to enable the vnx backend
#   Defaults to false
#
# [*cinder_enable_dellemc_xtremio_backend*]
#   (Optional) Whether to enable the xtremio backend
#   Defaults to false
#
# [*cinder_enable_ibm_svf_backend*]
#   (Optional) Whether to enable the ibm_svf backend
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
#[*cinder_enable_nvmeof_backend*]
#   (Optional) Whether to enable the NVMeOF backend
#   Defaults to false
#
# [*cinder_user_enabled_backends*]
#   (Optional) List of additional backend stanzas to activate
#   Defaults to lookup('cinder_user_enabled_backends', undef, undef, undef)
#
# [*cinder_volume_cluster*]
#   (Optional) Name of the cluster when running in active-active mode
#   Defaults to ''
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not
#   Defaults to lookup('enable_internal_tls', undef, undef, false)
#
# [*etcd_certificate_specs*]
#   (optional) TLS certificate specs for the etcd service
#   Defaults to lookup('tripleo::profile::base::etcd::certificate_specs', undef, undef, {})
#
# [*etcd_enabled*]
#   (optional) Whether the etcd service is enabled or not
#   Defaults to lookup('etcd_enabled', undef, undef, false)
#
# [*etcd_host*]
#   (optional) IP address (VIP) of the etcd service
#   Defaults to lookup('etcd_vip', undef, undef, undef)
#
# [*etcd_port*]
#   (optional) Port used by the etcd service
#   Defaults to lookup('tripleo::profile::base::etcd::client_port', undef, undef, '2379')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# DEPRECATED PARAMETERS
#
# [*cinder_rbd_client_name*]
#   (Optional) Name of RBD client
#   Defaults to undef
#
# [*cinder_rbd_ceph_conf_path*]
#   (Optional) The path where the Ceph Cluster config files are stored on the host
#   Defaults to undef
#
class tripleo::profile::base::cinder::volume (
  $cinder_enable_pure_backend                  = false,
  $cinder_enable_dellemc_sc_backend            = false,
  $cinder_enable_dellemc_unity_backend         = false,
  $cinder_enable_dellemc_powerflex_backend     = false,
  $cinder_enable_dellemc_powermax_backend      = false,
  $cinder_enable_dellemc_powerstore_backend    = false,
  $cinder_enable_dellemc_vnx_backend           = false,
  $cinder_enable_dellemc_xtremio_backend       = false,
  $cinder_enable_ibm_svf_backend               = false,
  $cinder_enable_iscsi_backend                 = true,
  $cinder_enable_netapp_backend                = false,
  $cinder_enable_nfs_backend                   = false,
  $cinder_enable_rbd_backend                   = false,
  $cinder_enable_nvmeof_backend                = false,
  $cinder_user_enabled_backends                = lookup('cinder_user_enabled_backends', undef, undef, undef),
  $cinder_volume_cluster                       = '',
  $enable_internal_tls                         = lookup('enable_internal_tls', undef, undef, false),
  $etcd_certificate_specs                      = lookup('tripleo::profile::base::etcd::certificate_specs', undef, undef, {}),
  $etcd_enabled                                = lookup('etcd_enabled', undef, undef, false),
  $etcd_host                                   = lookup('etcd_vip', undef, undef, undef),
  $etcd_port                                   = lookup('tripleo::profile::base::etcd::client_port', undef, undef, '2379'),
  $step                                        = Integer(lookup('step')),
  # DEPRECATED PARAMETERS
  $cinder_rbd_ceph_conf_path                   = undef,
  $cinder_rbd_client_name                      = undef,
) {
  include tripleo::profile::base::cinder

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
      case $::operatingsystemmajrelease {
        # el8 uses etcd version 3.2, which supports v3alpha path
        '8'     : { $api_version = 'v3alpha' }
        # el9 uses etcd version 3.4, which supports v3 path
        default : { $api_version = 'v3' }
      }
      $options_init = "?api_version=${api_version}"
      if $enable_internal_tls {
        $protocol = 'https'
        $tls_keyfile = $etcd_certificate_specs['service_key']
        $tls_certfile = $etcd_certificate_specs['service_certificate']
        $options_tls = sprintf('&cert_key=%s&cert_cert=%s', $tls_keyfile, $tls_certfile)
        $options = "${options_init}${options_tls}"
      } else {
        $protocol = 'http'
        $options = "${options_init}"
      }
      $backend_url = sprintf('etcd3+%s://%s:%s%s', $protocol, normalize_ip_for_uri($etcd_host), $etcd_port, $options)
      class { 'cinder::coordination' :
        backend_url => $backend_url,
      }
    }

    class { 'cinder::volume' :
      cluster => $cinder_volume_cluster_real,
    }

    if $cinder_enable_pure_backend {
      include tripleo::profile::base::cinder::volume::pure
      $cinder_pure_backend_name = lookup('cinder::backend::pure::volume_backend_name', undef, undef, 'tripleo_pure')
    } else {
      $cinder_pure_backend_name = undef
    }

    if $cinder_enable_dellemc_sc_backend {
      include tripleo::profile::base::cinder::volume::dellemc_sc
      $cinder_dellemc_sc_backend_name = lookup('cinder::backend::dellemc_sc::volume_backend_name', undef, undef, 'tripleo_dellemc_sc')
    } else {
      $cinder_dellemc_sc_backend_name = undef
    }

    if $cinder_enable_dellemc_unity_backend {
      include tripleo::profile::base::cinder::volume::dellemc_unity
      $cinder_dellemc_unity_backend_name = lookup('cinder::backend::dellemc_unity::volume_backend_name',
                                                  undef, undef, 'tripleo_dellemc_unity')
    } else {
      $cinder_dellemc_unity_backend_name = undef
    }

    if $cinder_enable_dellemc_powerflex_backend {
      include tripleo::profile::base::cinder::volume::dellemc_powerflex
      $cinder_dellemc_powerflex_backend_name = lookup('cinder::backend::dellemc_powerflex::volume_backend_name',
                                                      undef, undef, 'tripleo_dellemc_powerflex')
    } else {
      $cinder_dellemc_powerflex_backend_name = undef
    }

    if $cinder_enable_dellemc_powermax_backend {
      include tripleo::profile::base::cinder::volume::dellemc_powermax
      $cinder_dellemc_powermax_backend_name = lookup('cinder::backend::dellemc_powermax::volume_backend_name',
                                                    undef, undef, 'tripleo_dellemc_powermax')
    } else {
      $cinder_dellemc_powermax_backend_name = undef
    }

    if $cinder_enable_dellemc_powerstore_backend {
      include tripleo::profile::base::cinder::volume::dellemc_powerstore
      $cinder_dellemc_powerstore_backend_name = lookup('cinder::backend::dellemc_powerstore::volume_backend_name',
                                                      undef, undef, 'tripleo_dellemc_powerstore')
    } else {
      $cinder_dellemc_powerstore_backend_name = undef
    }

    if $cinder_enable_dellemc_vnx_backend {
      include tripleo::profile::base::cinder::volume::dellemc_vnx
      $cinder_dellemc_vnx_backend_name = lookup('cinder::backend::emc_vnx::volume_backend_name',
          undef, undef, 'tripleo_dellemc_vnx')
    } else {
      $cinder_dellemc_vnx_backend_name = undef
    }

    if $cinder_enable_dellemc_xtremio_backend {
      include tripleo::profile::base::cinder::volume::dellemc_xtremio
      $cinder_dellemc_xtremio_backend_name = lookup('cinder::backend::dellemc_xtremio::volume_backend_name',
          undef, undef, 'tripleo_dellemc_xtremio')
    } else {
      $cinder_dellemc_xtremio_backend_name = undef
    }

    if $cinder_enable_ibm_svf_backend {
      include tripleo::profile::base::cinder::volume::ibm_svf
      $cinder_ibm_svf_backend_name = lookup('cinder::backend::ibm_svf::volume_backend_name',
                                                    undef, undef, 'tripleo_ibm_svf')
    } else {
      $cinder_ibm_svf_backend_name = undef
    }

    if $cinder_enable_iscsi_backend {
      include tripleo::profile::base::cinder::volume::iscsi
      $cinder_iscsi_backend_name = lookup('cinder::backend::iscsi::volume_backend_name', undef, undef, 'tripleo_iscsi')
    } else {
      $cinder_iscsi_backend_name = undef
    }

    if $cinder_enable_netapp_backend {
      include tripleo::profile::base::cinder::volume::netapp
      $cinder_netapp_backend_name = lookup('cinder::backend::netapp::volume_backend_name', undef, undef, 'tripleo_netapp')
    } else {
      $cinder_netapp_backend_name = undef
    }

    if $cinder_enable_nfs_backend {
      include tripleo::profile::base::cinder::volume::nfs
      $cinder_nfs_backend_name = lookup('tripleo::profile::base::cinder::volume::nfs::backend_name',
                                        undef, undef, lookup('cinder::backend::nfs::volume_backend_name',
                                        undef, undef, 'tripleo_nfs'))
    } else {
      $cinder_nfs_backend_name = undef
    }

    if $cinder_enable_rbd_backend {
      include tripleo::profile::base::cinder::volume::rbd
      $cinder_rbd_backend_name = lookup('tripleo::profile::base::cinder::volume::rbd::backend_name',
                                        undef, undef, ['tripleo_ceph'])

      $extra_pools = lookup('tripleo::profile::base::cinder::volume::rbd::cinder_rbd_extra_pools', undef, undef, undef)
      if empty($extra_pools) {
        $extra_backend_names = []
      } else {
        # These $extra_pools are associated with the first backend
        $base_name = any2array($cinder_rbd_backend_name)[0]
        $extra_backend_names = any2array($extra_pools).map |$pool_name| { "${base_name}_${pool_name}" }
      }

      # Each $multi_config backend can specify its own list of extra pools. The
      # backend names are the $multi_config hash keys.
      $multi_config = lookup('tripleo::profile::base::cinder::volume::rbd::multi_config', undef, undef, {})
      $extra_multiconfig_backend_names = $multi_config.map |$base_name, $backend_config| {
        $backend_extra_pools = $backend_config['CinderRbdExtraPools']
        any2array($backend_extra_pools).map |$pool_name| { "${base_name}_${pool_name}" }
      }

      $cinder_rbd_extra_backend_names = flatten($extra_backend_names, $extra_multiconfig_backend_names)
    } else {
      $cinder_rbd_backend_name = undef
      $cinder_rbd_extra_backend_names = undef
    }

    if $cinder_enable_nvmeof_backend {
      include tripleo::profile::base::cinder::volume::nvmeof
      $cinder_nvmeof_backend_name = lookup('cinder::backend::nvmeof::volume_backend_name', undef, undef, 'tripleo_nvmeof')
    } else {
      $cinder_nvmeof_backend_name = undef
    }

    $backends = delete_undef_values(concat([], $cinder_iscsi_backend_name,
                                      $cinder_rbd_backend_name,
                                      $cinder_rbd_extra_backend_names,
                                      $cinder_pure_backend_name,
                                      $cinder_dellemc_sc_backend_name,
                                      $cinder_dellemc_unity_backend_name,
                                      $cinder_dellemc_powerflex_backend_name,
                                      $cinder_dellemc_powermax_backend_name,
                                      $cinder_dellemc_powerstore_backend_name,
                                      $cinder_dellemc_vnx_backend_name,
                                      $cinder_dellemc_xtremio_backend_name,
                                      $cinder_ibm_svf_backend_name,
                                      $cinder_netapp_backend_name,
                                      $cinder_nfs_backend_name,
                                      $cinder_user_enabled_backends,
                                      $cinder_nvmeof_backend_name))
    # NOTE(aschultz): during testing it was found that puppet 3 may incorrectly
    # include a "" in the previous array which is not removed by the
    # delete_undef_values function. So we need to make sure we don't have any
    # "" strings in our array.
    $cinder_enabled_backends = delete($backends, '')

    class { 'cinder::backends' :
      enabled_backends => $cinder_enabled_backends,
    }
    include cinder::backend::defaults
  }

}
