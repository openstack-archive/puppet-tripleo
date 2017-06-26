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
# == Class: tripleo::profile::pacemaker::database::redis_bundle
#
# Containerized Redis Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*redis_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::redis_bundle::redis_docker_image', undef)
#
# [*redis_docker_control_port*]
#   (Optional) The bundle's pacemaker_remote control port on the host
#   Defaults to hiera('tripleo::profile::pacemaker::redis_bundle::control_port', '3121')
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
class tripleo::profile::pacemaker::database::redis_bundle (
  $bootstrap_node            = hiera('redis_short_bootstrap_node_name'),
  $redis_docker_image        = hiera('tripleo::profile::pacemaker::database::redis_bundle::redis_docker_image', undef),
  $redis_docker_control_port = hiera('tripleo::profile::pacemaker::database::redis_bundle::control_port', '3124'),
  $pcs_tries                 = hiera('pcs_tries', 20),
  $step                      = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::database::redis

  if $step >= 2 {
    if $pacemaker_master {
      $redis_short_node_names = hiera('redis_short_node_names')
      $redis_nodes_count = count($redis_short_node_names)
      $redis_short_node_names.each |String $node_name| {
        pacemaker::property { "redis-role-${node_name}":
          property => 'redis-role',
          value    => true,
          tries    => $pcs_tries,
          node     => $node_name,
          before   => Pacemaker::Resource::Bundle['redis-bundle'],
        }
      }

      pacemaker::resource::bundle { 'redis-bundle':
        image             => $redis_docker_image,
        replicas          => $redis_nodes_count,
        masters           => 1,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['redis-role eq true'],
        },
        container_options => 'network=host',
        options           => '--user=root --log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS',
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        network           => "control-port=${redis_docker_control_port}",
        storage_maps      => {
          'redis-cfg-files'               => {
            'source-dir' => '/var/lib/kolla/config_files/redis.json',
            'target-dir' => '/var/lib/kolla/config_files/config.json',
            'options'    => 'ro',
          },
          'redis-cfg-data-redis'          => {
            'source-dir' => '/var/lib/config-data/puppet-generated/redis/',
            'target-dir' => '/var/lib/kolla/config_files/src',
            'options'    => 'ro',
          },
          'redis-hosts'                   => {
            'source-dir' => '/etc/hosts',
            'target-dir' => '/etc/hosts',
            'options'    => 'ro',
          },
          'redis-localtime'               => {
            'source-dir' => '/etc/localtime',
            'target-dir' => '/etc/localtime',
            'options'    => 'ro',
          },
          'redis-lib'                     => {
            'source-dir' => '/var/lib/redis',
            'target-dir' => '/var/lib/redis',
            'options'    => 'rw',
          },
          'redis-log'                     => {
            'source-dir' => '/var/log/redis',
            'target-dir' => '/var/log/redis',
            'options'    => 'rw',
          },
          'redis-run'                     => {
            'source-dir' => '/var/run/redis',
            'target-dir' => '/var/run/redis',
            'options'    => 'rw',
          },
          'redis-pki-extracted'           => {
            'source-dir' => '/etc/pki/ca-trust/extracted',
            'target-dir' => '/etc/pki/ca-trust/extracted',
            'options'    => 'ro',
          },
          'redis-pki-ca-bundle-crt'       => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'options'    => 'ro',
          },
          'redis-pki-ca-bundle-trust-crt' => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'options'    => 'ro',
          },
          'redis-pki-cert'                => {
            'source-dir' => '/etc/pki/tls/cert.pem',
            'target-dir' => '/etc/pki/tls/cert.pem',
            'options'    => 'ro',
          },
          'redis-dev-log'                 => {
            'source-dir' => '/dev/log',
            'target-dir' => '/dev/log',
            'options'    => 'rw',
          },
        },
      }

      pacemaker::resource::ocf { 'redis':
        ocf_agent_name  => 'heartbeat:redis',
        resource_params => 'wait_last_known_master=true',
        master_params   => '',
        meta_params     => 'notify=true ordered=true interleave=true',
        op_params       => 'start timeout=200s stop timeout=200s',
        tries           => $pcs_tries,
        location_rule   => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['redis-role eq true'],
        },
        bundle          => 'redis-bundle',
        require         => [Class['::redis'],
                            Pacemaker::Resource::Bundle['redis-bundle']],
      }

    }
  }
}
