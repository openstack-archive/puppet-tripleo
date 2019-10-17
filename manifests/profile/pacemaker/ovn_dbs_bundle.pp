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
# == Class: tripleo::profile::pacemaker::neutron::plugins::ml2::ovn
#
# Neutron ML2 driver Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*ovn_dbs_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::ovn_dbs_bundle::ovn_dbs_docker_image', undef)
#
# [*ovn_dbs_control_port*]
#   (Optional) The bundle's pacemaker_remote control port on the host
#   Defaults to hiera('tripleo::profile::pacemaker::ovn_dbs_bundle::control_port', '3125')
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('ovn_dbs_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#  (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*ovn_dbs_vip*]
#   (Optional) The vip to be used for OVN DB servers. It is expected that
#   the vip resource to be created before calling this class.
#   Defaults to hiera('ovn_dbs_vip')
#
# [*nb_db_port*]
#   The TCP port in which the OVN Northbound DB listens to.
#   Defaults to 6641
#
# [*sb_db_port*]
#   The TCP port in which the OVN Southbound DB listens to.
#   Defaults to 6642
#
# [*tls_priorities*]
#   (optional) Sets PCMK_tls_priorities in /etc/sysconfig/pacemaker when set
#   Defaults to hiera('tripleo::pacemaker::tls_priorities', undef)
#
# [*dbs_timeout*]
#   (Optional) timeout for monitor of ovn dbs resource
#   Defaults to 60
#

class tripleo::profile::pacemaker::ovn_dbs_bundle (
  $ovn_dbs_docker_image = hiera('tripleo::profile::pacemaker::ovn_dbs_bundle::ovn_dbs_docker_image', undef),
  $ovn_dbs_control_port = hiera('tripleo::profile::pacemaker::ovn_dbs_bundle::control_port', '3125'),
  $bootstrap_node       = hiera('ovn_dbs_short_bootstrap_node_name'),
  $step                 = Integer(hiera('step')),
  $pcs_tries            = hiera('pcs_tries', 20),
  $ovn_dbs_vip          = hiera('ovn_dbs_vip'),
  $nb_db_port           = 6641,
  $sb_db_port           = 6642,
  $tls_priorities       = hiera('tripleo::pacemaker::tls_priorities', undef),
  $dbs_timeout          = hiera('tripleo::profile::pacemaker::ovn_dbs_bundle::dbs_timeout', 60),
) {

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $step >= 3 {

    if $pacemaker_master {
      $ovndb_servers_resource_name = 'ovndb_servers'
      $ovndb_servers_ocf_name      = 'ovn:ovndb-servers'
      $ovndb_vip_resource_name     = "ip-${ovn_dbs_vip}"

      $ovn_dbs_short_node_names = hiera('ovn_dbs_short_node_names')
      $ovn_dbs_nodes_count = count($ovn_dbs_short_node_names)
      $ovn_dbs_short_node_names.each |String $node_name| {
        pacemaker::property { "ovn-dbs-role-${node_name}":
          property => 'ovn-dbs-role',
          value    => true,
          tries    => $pcs_tries,
          node     => downcase($node_name),
          before   => Pacemaker::Resource::Bundle['ovn-dbs-bundle'],
        }
      }
      $ovn_dbs_vip_norm = normalize_ip_for_uri($ovn_dbs_vip)
      $ovn_dbs_location_rule = {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['ovn-dbs-role eq true'],
      }
      if $tls_priorities != undef {
        $tls_priorities_real = " -e PCMK_tls_priorities=${tls_priorities}"
      } else {
        $tls_priorities_real = ''
      }

      pacemaker::resource::bundle { 'ovn-dbs-bundle':
        image             => $ovn_dbs_docker_image,
        replicas          => $ovn_dbs_nodes_count,
        masters           => 1,
        location_rule     => $ovn_dbs_location_rule,
        container_options => 'network=host',
        options           => "--log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS${tls_priorities_real}",
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        network           => "control-port=${ovn_dbs_control_port}",
        storage_maps      => {
          'ovn-dbs-cfg-files' => {
            'source-dir' => '/var/lib/kolla/config_files/ovn_dbs.json',
            'target-dir' => '/var/lib/kolla/config_files/config.json',
            'options'    => 'ro',
          },
          'ovn-dbs-mod-files' => {
            'source-dir' => '/lib/modules',
            'target-dir' => '/lib/modules',
            'options'    => 'ro',
          },
          'ovn-dbs-run-files' => {
            'source-dir' => '/var/lib/openvswitch/ovn',
            'target-dir' => '/run/openvswitch',
            'options'    => 'rw',
          },
          'ovn-dbs-log-files' => {
            'source-dir' => '/var/log/containers/openvswitch',
            'target-dir' => '/var/log/openvswitch',
            'options'    => 'rw',
          },
          'ovn-dbs-db-path'   => {
            'source-dir' => '/var/lib/openvswitch/ovn',
            'target-dir' => '/etc/openvswitch',
            'options'    => 'rw',
          },
        },
      }

      pacemaker::resource::ocf { "${ovndb_servers_resource_name}":
        ocf_agent_name  => "${ovndb_servers_ocf_name}",
        master_params   => '',
        op_params       => "start timeout=200s stop timeout=200s monitor interval=10s role=Master timeout=${dbs_timeout}s \
monitor interval=30s role=Slave timeout=${dbs_timeout}s",
        resource_params => "master_ip=${ovn_dbs_vip_norm} nb_master_port=${nb_db_port} \
sb_master_port=${sb_db_port} manage_northd=yes inactive_probe_interval=180000",
        tries           => $pcs_tries,
        location_rule   => $ovn_dbs_location_rule,
        meta_params     => 'notify=true container-attribute-target=host',
        bundle          => 'ovn-dbs-bundle',
      }

      pacemaker::constraint::colocation { "${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}":
        source       => "${ovndb_vip_resource_name}",
        target       => 'ovn-dbs-bundle',
        master_slave => true,
        score        => 'INFINITY',
        tries        => $pcs_tries,
      }

      pacemaker::constraint::order { "${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}":
        first_resource    => 'ovn-dbs-bundle',
        second_resource   => "${ovndb_vip_resource_name}",
        first_action      => 'promote',
        second_action     => 'start',
        constraint_params => 'kind=Optional',
        tries             => $pcs_tries,
      }

      Pacemaker::Resource::Bundle['ovn-dbs-bundle']
        -> Pacemaker::Resource::Ocf["${ovndb_servers_resource_name}"]
          -> Pacemaker::Constraint::Order["${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}"]
            -> Pacemaker::Constraint::Colocation["${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}"]
    }
  }
}
