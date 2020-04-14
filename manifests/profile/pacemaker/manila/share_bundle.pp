# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::pacemaker::manila::share_bundle
#
# Containerized Redis Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*ceph_nfs_enabled*]
#   (Optional) Whether or not the ceph_nfs service is enabled
#   Defaults to hiera('ceph_nfs_enabled', false)
#
# [*manila_share_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::manila::share_bundle::manila_docker_image', undef)
#
# [*docker_volumes*]
#   (Optional) The list of volumes to be mounted in the docker container
#   Defaults to []
#
# [*docker_environment*]
#   (Optional) List or Hash of environment variables set in the docker container
#   Defaults to {'KOLLA_CONFIG_STRATEGY' => 'COPY_ALWAYS'}
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('redis_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*container_backend*]
#   (optional) Container backend to use when creating the bundle
#   Defaults to 'docker'
#
# [*log_driver*]
#   (optional) Container log driver to use. When set to undef it uses 'k8s-file'
#   when container_cli is set to podman and 'journald' when it is set to docker.
#   Defaults to undef
#
# [*log_file*]
#   (optional) Container log file to use. Only relevant when log_driver is
#   set to 'k8s-file'.
#   Defaults to '/var/log/containers/stdouts/openstack-manila-share.log'
#
# [*tls_priorities*]
#   (optional) Sets PCMK_tls_priorities in /etc/sysconfig/pacemaker when set
#   Defaults to hiera('tripleo::pacemaker::tls_priorities', undef)
#
# [*bundle_user*]
#   (optional) Set the --user= switch to be passed to pcmk
#   Defaults to 'root'
#
class tripleo::profile::pacemaker::manila::share_bundle (
  $bootstrap_node             = hiera('manila_share_short_bootstrap_node_name'),
  $manila_share_docker_image  = hiera('tripleo::profile::pacemaker::manila::share_bundle::manila_share_docker_image', undef),
  $docker_volumes             = [],
  $docker_environment         = {'KOLLA_CONFIG_STRATEGY' => 'COPY_ALWAYS'},
  $ceph_nfs_enabled           = hiera('ceph_nfs_enabled', false),
  $container_backend          = 'docker',
  $tls_priorities             = hiera('tripleo::pacemaker::tls_priorities', undef),
  $bundle_user                = 'root',
  $log_driver                 = undef,
  $log_file                   = '/var/log/containers/stdouts/openstack-manila-share.log',
  $pcs_tries                  = hiera('pcs_tries', 20),
  $step                       = Integer(hiera('step')),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $log_driver == undef {
    if hiera('container_cli', 'docker') == 'podman' {
      $log_driver_real = 'k8s-file'
    } else {
      $log_driver_real = 'journald'
    }
  } else {
    $log_driver_real = $log_driver
  }
  if $log_driver_real == 'k8s-file' {
    $log_file_real = " --log-opt path=${log_file}"
  } else {
    $log_file_real = ''
  }
  include tripleo::profile::base::manila::share

  if $step >= 2 and $pacemaker_master {
    $manila_share_short_node_names = hiera('manila_share_short_node_names')

    if (hiera('pacemaker_short_node_names_override', undef)) {
      $pacemaker_short_node_names = hiera('pacemaker_short_node_names_override')
    } else {
      $pacemaker_short_node_names = hiera('pacemaker_short_node_names')
    }

    $pcmk_cinder_volume_nodes = intersection($manila_share_short_node_names, $pacemaker_short_node_names)
    $pcmk_cinder_volume_nodes.each |String $node_name| {
      pacemaker::property { "manila-share-role-${node_name}":
        property => 'manila-share-role',
        value    => true,
        tries    => $pcs_tries,
        node     => downcase($node_name),
        before   => Pacemaker::Resource::Bundle[$::manila::params::share_service],
      }
    }
  }

  if $step >= 5 {
    if $pacemaker_master {
      $manila_cephfs_protocol_helper_type = hiera('manila::backend::cephfs::cephfs_protocol_helper_type', '')
      $docker_vol_arr = delete(any2array($docker_volumes), '').flatten()

      unless empty($docker_vol_arr) {
        $storage_maps = docker_volumes_to_storage_maps($docker_vol_arr, 'manila-share')
      } else {
        notice('Using fixed list of docker volumes for manila-share bundle')
        # Default to previous hard-coded list
        $default_storage_maps = {
          'manila-share-cfg-files'               => {
            'source-dir' => '/var/lib/kolla/config_files/manila_share.json',
            'target-dir' => '/var/lib/kolla/config_files/config.json',
            'options'    => 'ro',
          },
          'manila-share-cfg-data'                => {
            'source-dir' => '/var/lib/config-data/puppet-generated/manila/',
            'target-dir' => '/var/lib/kolla/config_files/src',
            'options'    => 'ro',
          },
          'manila-share-hosts'                   => {
            'source-dir' => '/etc/hosts',
            'target-dir' => '/etc/hosts',
            'options'    => 'ro',
          },
          'manila-share-localtime'               => {
            'source-dir' => '/etc/localtime',
            'target-dir' => '/etc/localtime',
            'options'    => 'ro',
          },
          'manila-share-dev'                     => {
            'source-dir' => '/dev',
            'target-dir' => '/dev',
            'options'    => 'rw',
          },
          'manila-share-run'                     => {
            'source-dir' => '/run',
            'target-dir' => '/run',
            'options'    => 'rw',
          },
          'manila-share-sys'                     => {
            'source-dir' => '/sys',
            'target-dir' => '/sys',
            'options'    => 'rw',
          },
          'manila-share-lib-modules'             => {
            'source-dir' => '/lib/modules',
            'target-dir' => '/lib/modules',
            'options'    => 'ro',
          },
          'manila-share-var-lib-manila'          => {
            'source-dir' => '/var/lib/manila',
            'target-dir' => '/var/lib/manila',
            'options'    => 'rw',
          },
          'manila-share-pki-extracted'           => {
            'source-dir' => '/etc/pki/ca-trust/extracted',
            'target-dir' => '/etc/pki/ca-trust/extracted',
            'options'    => 'ro',
          },
          'manila-share-pki-ca-bundle-crt'       => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'options'    => 'ro',
          },
          'manila-share-pki-ca-bundle-trust-crt' => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'options'    => 'ro',
          },
          'manila-share-pki-cert'                => {
            'source-dir' => '/etc/pki/tls/cert.pem',
            'target-dir' => '/etc/pki/tls/cert.pem',
            'options'    => 'ro',
          },
          'manila-share-var-log'                 => {
            'source-dir' => '/var/log/containers/manila',
            'target-dir' => '/var/log/manila',
            'options'    => 'rw',
          },
          'manila-share-ceph-cfg-dir'            => {
            'source-dir' => '/etc/ceph',
            'target-dir' => '/etc/ceph',
            'options'    => 'ro',
          },
        }

        # if ceph-nfs backend is used, then DBus is used for dynamic
        # creation of NFS exports and DBus socket has to be mounted
        # both to manila-share and ganesha containers so they can talk
        # to each other
        if $ceph_nfs_enabled {
          $extra_storage_maps = {
            'manila-share-dbus-docker' => {
              'source-dir' => '/var/run/dbus/system_bus_socket',
              'target-dir' => '/var/run/dbus/system_bus_socket',
              'options'    => 'rw',
            },
            'manila-share-etc-ganesha' => {
              'source-dir' => '/etc/ganesha',
              'target-dir' => '/etc/ganesha',
              'options'    => 'rw',
            },
          }
        } else {
          $extra_storage_maps = {}
        }

        $storage_maps = merge($default_storage_maps, $extra_storage_maps)
      }

      if is_hash($docker_environment) {
        $docker_env = join($docker_environment.map |$index, $value| { "-e ${index}=${value}" }, ' ')
      } else {
        $docker_env_arr = delete(any2array($docker_environment), '').flatten()
        $docker_env = join($docker_env_arr.map |$var| { "-e ${var}" }, ' ')
      }

      if $tls_priorities != undef {
        $tls_priorities_real = " -e PCMK_tls_priorities=${tls_priorities}"
      } else {
        $tls_priorities_real = ''
      }
      pacemaker::resource::bundle { $::manila::params::share_service:
        image             => $manila_share_docker_image,
        replicas          => 1,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['manila-share-role eq true'],
        },
        container_options => 'network=host',
        # lint:ignore:140chars
        options           => "--ipc=host --privileged=true --user=${bundle_user} --log-driver=${log_driver_real}${log_file_real} ${docker_env}${tls_priorities_real}",
        # lint:endignore
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        storage_maps      => $storage_maps,
        container_backend => $container_backend,
      }

      if $ceph_nfs_enabled {
        pacemaker::constraint::order { 'ceph-nfs-then-manila-share':
          first_resource    => 'ceph-nfs',
          second_resource   => 'openstack-manila-share',
          first_action      => 'start',
          second_action     => 'start',
          constraint_params => 'kind=Optional',
          tries             => $pcs_tries,
          tag               => 'pacemaker_constraint',
        }

        pacemaker::constraint::colocation { 'openstack-manila-share-with-ceph-nfs':
          source => 'openstack-manila-share',
          target => 'ceph-nfs',
          score  => 'INFINITY',
          tries  => $pcs_tries,
          tag    => 'pacemaker_constraint',
        }

        Pacemaker::Resource::Bundle['openstack-manila-share']
          -> Pacemaker::Constraint::Colocation['openstack-manila-share-with-ceph-nfs']
            -> Pacemaker::Constraint::Order['ceph-nfs-then-manila-share']
      }
    }
  }
}
