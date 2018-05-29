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
# [*backend_cephfs_enabled*]
#   (Optional) Whether or not the cephfs backend is enabled
#   Defaults to hiera('manila_backend_cephfs_enabled', false)
#
# [*manila_share_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::manila::share_bundle::manila_docker_image', undef)
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
#
class tripleo::profile::pacemaker::manila::share_bundle (
  $bootstrap_node             = hiera('manila_share_short_bootstrap_node_name'),
  $manila_share_docker_image  = hiera('tripleo::profile::pacemaker::manila::share_bundle::manila_share_docker_image', undef),
  $backend_cephfs_enabled     = hiera('manila_backend_cephfs_enabled', false),
  $pcs_tries                  = hiera('pcs_tries', 20),
  $step                       = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::manila::share

  if $step >= 2 and $pacemaker_master {
    $manila_share_short_node_names = hiera('manila_share_short_node_names')
    $manila_share_short_node_names.each |String $node_name| {
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
      $manila_share_nodes_count = count(hiera('manila_share_short_node_names', []))

      $default_storage_maps = {
        'manila-share-cfg-files'      => {
          'source-dir' => '/var/lib/kolla/config_files/manila_share.json',
          'target-dir' => '/var/lib/kolla/config_files/config.json',
          'options'    => 'ro',
        },
        'manila-share-cfg-data'       => {
          'source-dir' => '/var/lib/config-data/puppet-generated/manila/',
          'target-dir' => '/var/lib/kolla/config_files/src',
          'options'    => 'ro',
        },
        'manila-share-hosts'          => {
          'source-dir' => '/etc/hosts',
          'target-dir' => '/etc/hosts',
          'options'    => 'ro',
        },
        'manila-share-localtime'      => {
          'source-dir' => '/etc/localtime',
          'target-dir' => '/etc/localtime',
          'options'    => 'ro',
        },
        'manila-share-dev'            => {
          'source-dir' => '/dev',
          'target-dir' => '/dev',
          'options'    => 'rw',
        },
        'manila-share-run'            => {
          'source-dir' => '/run',
          'target-dir' => '/run',
          'options'    => 'rw',
        },
        'manila-share-sys'            => {
          'source-dir' => '/sys',
          'target-dir' => '/sys',
          'options'    => 'rw',
        },
        'manila-share-lib-modules'    => {
          'source-dir' => '/lib/modules',
          'target-dir' => '/lib/modules',
          'options'    => 'ro',
        },
        'manila-share-var-lib-manila' => {
          'source-dir' => '/var/lib/manila',
          'target-dir' => '/var/lib/manila',
          'options'    => 'rw',
        },
        'manila-share-var-log'        => {
          'source-dir' => '/var/log/containers/manila',
          'target-dir' => '/var/log/manila',
          'options'    => 'rw',
        },
        'ceph-cfg-dir'                => {
          'source-dir' => '/etc/ceph',
          'target-dir' => '/etc/ceph',
          'options'    => 'ro',
        },
      }

      # if ceph-nfs backend is used, then DBus is used for dynamic
      # creation of NFS exports and DBus socket has to be mounted
      # both to manila-share and ganesha containers so they can talk
      # to each other
      $manila_cephfs_protocol_helper_type = hiera('manila::backend::cephfs::cephfs_protocol_helper_type', '')
      $nfs_ganesha = ($backend_cephfs_enabled and $manila_cephfs_protocol_helper_type == 'NFS')
      if $nfs_ganesha {
        $extra_storage_maps = {
          'dbus-docker'                => {
            'source-dir' => '/var/run/dbus/system_bus_socket',
            'target-dir' => '/var/run/dbus/system_bus_socket',
            'options'    => 'rw',
          },
          'etc-ganesha'                => {
            'source-dir' => '/etc/ganesha',
            'target-dir' => '/etc/ganesha',
            'options'    => 'rw',
          },
        }
      } else {
        $extra_storage_maps = {}
      }

      $storage_maps = merge($default_storage_maps, $extra_storage_maps)

      pacemaker::resource::bundle { $::manila::params::share_service:
        image             => $manila_share_docker_image,
        replicas          => 1,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['manila-share-role eq true'],
        },
        container_options => 'network=host',
        options           => '--ipc=host --privileged=true --user=root --log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS',
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        storage_maps      => $storage_maps,
      }

      if $nfs_ganesha {
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
