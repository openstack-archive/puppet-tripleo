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
# == Class: tripleo::profile::pacemaker::cinder::backup_bundle
#
# Containerized Redis Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*cinder_backup_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::cinder::backup_bundle::cinder_docker_image', undef)
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
class tripleo::profile::pacemaker::cinder::backup_bundle (
  $bootstrap_node             = hiera('cinder_backup_short_bootstrap_node_name'),
  $cinder_backup_docker_image = hiera('tripleo::profile::pacemaker::cinder::backup_bundle::cinder_backup_docker_image', undef),
  $pcs_tries                  = hiera('pcs_tries', 20),
  $step                       = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::cinder::backup

  if $step >= 2 and $pacemaker_master {
    $cinder_backup_short_node_names = hiera('cinder_backup_short_node_names')
    $cinder_backup_short_node_names.each |String $node_name| {
      pacemaker::property { "cinder-backup-role-${node_name}":
        property => 'cinder-backup-role',
        value    => true,
        tries    => $pcs_tries,
        node     => $node_name,
        before   => Pacemaker::Resource::Bundle[$::cinder::params::backup_service],
      }
    }
  }

  if $step >= 5 {
    if $pacemaker_master {
      $cinder_backup_nodes_count = count(hiera('cinder_backup_short_node_names', []))

      pacemaker::resource::bundle { $::cinder::params::backup_service :
        image             => $cinder_backup_docker_image,
        replicas          => 1,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['cinder-backup-role eq true'],
        },
        container_options => 'network=host',
        options           => '--ipc=host --privileged=true --user=root --log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS',
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        storage_maps      => {
          'cinder-backup-cfg-files'      => {
            'source-dir' => '/var/lib/kolla/config_files/cinder_backup.json',
            'target-dir' => '/var/lib/kolla/config_files/config.json',
            'options'    => 'ro',
          },
          'cinder-backup-cfg-data'       => {
            'source-dir' => '/var/lib/config-data/cinder/etc/cinder',
            'target-dir' => '/etc/cinder',
            'options'    => 'ro',
          },
          'cinder-backup-cfg-ceph'       => {
            'source-dir' => '/var/lib/config-data/cinder/etc/ceph',
            'target-dir' => '/etc/ceph',
            'options'    => 'ro',
          },
          'cinder-backup-hosts'          => {
            'source-dir' => '/etc/hosts',
            'target-dir' => '/etc/hosts',
            'options'    => 'ro',
          },
          'cinder-backup-localtime'      => {
            'source-dir' => '/etc/localtime',
            'target-dir' => '/etc/localtime',
            'options'    => 'ro',
          },
          'cinder-backup-dev'            => {
            'source-dir' => '/dev',
            'target-dir' => '/dev',
            'options'    => 'rw',
          },
          'cinder-backup-run'            => {
            'source-dir' => '/run',
            'target-dir' => '/run',
            'options'    => 'rw',
          },
          'cinder-backup-sys'            => {
            'source-dir' => '/sys',
            'target-dir' => '/sys',
            'options'    => 'rw',
          },
          'cinder-backup-lib-modules'    => {
            'source-dir' => '/lib/modules',
            'target-dir' => '/lib/modules',
            'options'    => 'ro',
          },
          'cinder-backup-iscsi'          => {
            'source-dir' => '/etc/iscsi',
            'target-dir' => '/etc/iscsi',
            'options'    => 'rw',
          },
          'cinder-backup-var-lib-cinder' => {
            'source-dir' => '/var/lib/cinder',
            'target-dir' => '/var/lib/cinder',
            'options'    => 'rw',
          },
          'cinder-backup-var-log'        => {
            'source-dir' => '/var/log/containers/cinder',
            'target-dir' => '/var/log/cinder',
            'options'    => 'rw',
          },
        },
      }
    }
  }
}
