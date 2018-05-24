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
# == Class: tripleo::profile::pacemaker::cinder::volume_bundle
#
# Containerized Redis Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*cinder_volume_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::cinder::volume_bundle::cinder_docker_image', undef)
#
# [*docker_volumes*]
#   (Optional) The list of volumes to be mounted in the docker container
#   Defaults to []
#
# [*docker_environment*]
#   (Optional) The list of environment variables set in the docker container
#   Defaults to ['KOLLA_CONFIG_STRATEGY=COPY_ALWAYS']
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
class tripleo::profile::pacemaker::cinder::volume_bundle (
  $bootstrap_node             = hiera('cinder_volume_short_bootstrap_node_name'),
  $cinder_volume_docker_image = hiera('tripleo::profile::pacemaker::cinder::volume_bundle::cinder_volume_docker_image', undef),
  $docker_volumes             = [],
  $docker_environment         = ['KOLLA_CONFIG_STRATEGY=COPY_ALWAYS'],
  $pcs_tries                  = hiera('pcs_tries', 20),
  $step                       = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::cinder::volume

  if $step >= 2 and $pacemaker_master {
    $cinder_volume_short_node_names = hiera('cinder_volume_short_node_names')
    $cinder_volume_short_node_names.each |String $node_name| {
      pacemaker::property { "cinder-volume-role-${node_name}":
        property => 'cinder-volume-role',
        value    => true,
        tries    => $pcs_tries,
        node     => downcase($node_name),
        before   => Pacemaker::Resource::Bundle[$::cinder::params::volume_service],
      }
    }
  }

  if $step >= 5 {
    if $pacemaker_master {
      $cinder_volume_nodes_count = count(hiera('cinder_volume_short_node_names', []))

      $docker_vol_arr = delete(any2array($docker_volumes), '').flatten()

      unless empty($docker_vol_arr) {
        $storage_maps = docker_volumes_to_storage_maps($docker_vol_arr, 'cinder-volume')
      } else {
        notice('Using fixed list of docker volumes for cinder-volume bundle')
        # Default to previous hard-coded list
        $storage_maps = {
          'cinder-volume-cfg-files'               => {
            'source-dir' => '/var/lib/kolla/config_files/cinder_volume.json',
            'target-dir' => '/var/lib/kolla/config_files/config.json',
            'options'    => 'ro',
          },
          'cinder-volume-cfg-data'                => {
            'source-dir' => '/var/lib/config-data/puppet-generated/cinder/',
            'target-dir' => '/var/lib/kolla/config_files/src',
            'options'    => 'ro',
          },
          'cinder-volume-hosts'                   => {
            'source-dir' => '/etc/hosts',
            'target-dir' => '/etc/hosts',
            'options'    => 'ro',
          },
          'cinder-volume-localtime'               => {
            'source-dir' => '/etc/localtime',
            'target-dir' => '/etc/localtime',
            'options'    => 'ro',
          },
          'cinder-volume-dev'                     => {
            'source-dir' => '/dev',
            'target-dir' => '/dev',
            'options'    => 'rw',
          },
          'cinder-volume-run'                     => {
            'source-dir' => '/run',
            'target-dir' => '/run',
            'options'    => 'rw',
          },
          'cinder-volume-sys'                     => {
            'source-dir' => '/sys',
            'target-dir' => '/sys',
            'options'    => 'rw',
          },
          'cinder-volume-lib-modules'             => {
            'source-dir' => '/lib/modules',
            'target-dir' => '/lib/modules',
            'options'    => 'ro',
          },
          'cinder-volume-iscsi'                   => {
            'source-dir' => '/etc/iscsi',
            'target-dir' => '/var/lib/kolla/config_files/src-iscsid',
            'options'    => 'ro',
          },
          'cinder-volume-var-lib-cinder'          => {
            'source-dir' => '/var/lib/cinder',
            'target-dir' => '/var/lib/cinder',
            'options'    => 'rw',
          },
          'cinder-volume-pki-extracted'           => {
            'source-dir' => '/etc/pki/ca-trust/extracted',
            'target-dir' => '/etc/pki/ca-trust/extracted',
            'options'    => 'ro',
          },
          'cinder-volume-pki-ca-bundle-crt'       => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'options'    => 'ro',
          },
          'cinder-volume-pki-ca-bundle-trust-crt' => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'options'    => 'ro',
          },
          'cinder-volume-pki-cert'                => {
            'source-dir' => '/etc/pki/tls/cert.pem',
            'target-dir' => '/etc/pki/tls/cert.pem',
            'options'    => 'ro',
          },
          'cinder-volume-var-log'                 => {
            'source-dir' => '/var/log/containers/cinder',
            'target-dir' => '/var/log/cinder',
            'options'    => 'rw',
          },
          'cinder-volume-ceph-cfg-dir'            => {
            'source-dir' => '/etc/ceph',
            'target-dir' => '/var/lib/kolla/config_files/src-ceph/',
            'options'    => 'ro',
          },
        }
      }

      $docker_env_arr = delete(any2array($docker_environment), '').flatten()
      $docker_env = join($docker_env_arr.map |$var| { "-e ${var}" }, ' ')

      pacemaker::resource::bundle { $::cinder::params::volume_service:
        image             => $cinder_volume_docker_image,
        replicas          => 1,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['cinder-volume-role eq true'],
        },
        container_options => 'network=host',
        options           => "--ipc=host --privileged=true --user=root --log-driver=journald ${docker_env}",
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        storage_maps      => $storage_maps,
      }
    }
  }
}
