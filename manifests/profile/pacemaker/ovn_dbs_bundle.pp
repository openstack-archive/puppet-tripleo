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
# [*meta_params*]
#   (optional) Additional meta parameters to pass to "pcs resource create" for the VIP
#   Defaults to ''
#
# [*op_params*]
#   (optional) Additional op parameters to pass to "pcs resource create" for the VIP
#   Defaults to ''
#
# [*container_backend*]
#   (optional) Container backend to use when creating the bundle
#   Defaults to 'docker'
#
# [*tls_priorities*]
#   (optional) Sets PCMK_tls_priorities in /etc/sysconfig/pacemaker when set
#   Defaults to hiera('tripleo::pacemaker::tls_priorities', undef)
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*ca_file*]
#   (Optional) The path to the CA file that will be used for the TLS
#   configuration. It's only used if internal TLS is enabled.
#   Defaults to undef
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
  $meta_params          = '',
  $op_params            = '',
  $container_backend    = 'docker',
  $tls_priorities       = hiera('tripleo::pacemaker::tls_priorities', undef),
  $enable_internal_tls  = hiera('enable_internal_tls', false),
  $ca_file              = undef,
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
      $storage_maps = {
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
        'ovn-dbs-new-run-files' => {
          'source-dir' => '/var/lib/openvswitch/ovn',
          'target-dir' => '/run/ovn',
          'options'    => 'rw',
        },
        'ovn-dbs-log-files' => {
          'source-dir' => '/var/log/containers/openvswitch',
          'target-dir' => '/var/log/openvswitch',
          'options'    => 'rw',
        },
        'ovn-dbs-new-log-files' => {
          'source-dir' => '/var/log/containers/openvswitch',
          'target-dir' => '/var/log/ovn',
          'options'    => 'rw',
        },
        'ovn-dbs-db-path'   => {
          'source-dir' => '/var/lib/openvswitch/ovn',
          'target-dir' => '/etc/openvswitch',
          'options'    => 'rw',
        },
        'ovn-dbs-new-db-path'   => {
          'source-dir' => '/var/lib/openvswitch/ovn',
          'target-dir' => '/etc/ovn',
          'options'    => 'rw',
        },
      }
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
      $resource_params = "master_ip=${ovn_dbs_vip_norm} nb_master_port=${nb_db_port} \
sb_master_port=${sb_db_port} manage_northd=yes inactive_probe_interval=180000"
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

      if $enable_internal_tls {
        $ovn_storage_maps_tls = {
          'ovn-dbs-pki-'  => {
            'source-dir' => '/etc/pki/tls/private/ovn_dbs.key',
            'target-dir' => '/etc/pki/tls/private/ovn_dbs.key',
            'options'    => 'ro',
          },
          'ovn-dbs-cert' => {
            'source-dir' => '/etc/pki/tls/certs/ovn_dbs.crt',
            'target-dir' => '/etc/pki/tls/certs/ovn_dbs.crt',
            'options'    => 'ro',
          },
          'ovn-dbs-cacert' => {
            'source-dir' => "${ca_file}",
            'target-dir' => "${ca_file}",
            'options'    => 'ro',
          },
        }
        $tls_params = " ovn_nb_db_privkey=/etc/pki/tls/private/ovn_dbs.key  ovn_nb_db_cert=/etc/pki/tls/certs/ovn_dbs.crt \
ovn_nb_db_cacert=${ca_file} ovn_sb_db_privkey=/etc/pki/tls/private/ovn_dbs.key  \
ovn_sb_db_cert=/etc/pki/tls/certs/ovn_dbs.crt ovn_sb_db_cacert=${ca_file} \
nb_master_protocol=ssl sb_master_protocol=ssl"
      } else {
        $tls_params = ''
        $ovn_storage_maps_tls = {}
      }
      $resource_map = "${resource_params}${tls_params}"
      pacemaker::resource::bundle { 'ovn-dbs-bundle':
        image             => $ovn_dbs_docker_image,
        replicas          => $ovn_dbs_nodes_count,
        masters           => 1,
        location_rule     => $ovn_dbs_location_rule,
        container_options => 'network=host',
        options           => "--log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS${tls_priorities_real}",
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        network           => "control-port=${ovn_dbs_control_port}",
        storage_maps      => merge($storage_maps, $ovn_storage_maps_tls),
        container_backend => $container_backend,
        tries             => $pcs_tries,
      }

      pacemaker::resource::ocf { "${ovndb_servers_resource_name}":
        ocf_agent_name  => "${ovndb_servers_ocf_name}",
        master_params   => '',
        op_params       => 'start timeout=200s stop timeout=200s',
        resource_params => $resource_map,
        tries           => $pcs_tries,
        location_rule   => $ovn_dbs_location_rule,
        meta_params     => 'notify=true container-attribute-target=host',
        bundle          => 'ovn-dbs-bundle',
      }

      # This code tells us if ovn_dbs is using a separate ip or is using a the per-network VIP
      $ovn_dbs_network = hiera('ovn_dbs_network', undef)
      $net_vip_map = hiera('network_virtual_ips', undef)
      if $ovn_dbs_network != undef and $net_vip_map != undef and $ovn_dbs_network in $net_vip_map {
        $old_vip = $net_vip_map[$ovn_dbs_network]['ip_address']
        if $old_vip != $ovn_dbs_vip {
          $ovn_separate_vip = true
        } else {
          $ovn_separate_vip = false
        }
      } else {
          $ovn_separate_vip = false
      }

      # We create a separate VIP only in case OVN has been configured so via THT
      # in the non-separate case it will be created in the haproxy vip manifests
      if $ovn_separate_vip {
        if is_ipv6_address($ovn_dbs_vip) {
          $netmask        = '128'
          $nic            = interface_for_ip($ovn_dbs_vip)
          $ipv6_addrlabel = '99'
        } else {
          $netmask        = '32'
          $nic            = ''
          $ipv6_addrlabel = ''
        }

        pacemaker::resource::ip { "${ovndb_vip_resource_name}":
          ip_address     => $ovn_dbs_vip,
          cidr_netmask   => $netmask,
          nic            => $nic,
          ipv6_addrlabel => $ipv6_addrlabel,
          location_rule  => $ovn_dbs_location_rule,
          meta_params    => "resource-stickiness=INFINITY ${meta_params}",
          op_params      => $op_params,
          tries          => $pcs_tries,
        }
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

      # (bandini) we can remove this old constraint removal piece once queens is out of support
      # If we do a minor update or a redeploy against a cloud that did not already have the
      # separate OVN VIP, we want to be sure that the old constraints are gone. At this
      # point we cannot use the ovndb_resource_name because that is now the new IP
      # To be on the safe side, we fetch the network that ovn_dbs is supposed to listen on
      # hiera('ovn_dbs_network') and find out the VIP on that network
      # NB: we cannot use ensure -> absent and a pacmeaker constraint resource because we would
      # get duplicate resource errors, hence the exec usage
      if hiera('stack_action') == 'UPDATE' and $ovn_separate_vip {
        # We only remove these constraints if we're sure the ovn_dbs VIP is different
        # from the old VIP
        $old_vip_name = "ip-${old_vip}"
        $old_order_constraint = "order-ovn-dbs-bundle-${old_vip_name}-Optional"
        exec { "remove-old-${old_vip_name}-order-${ovndb_servers_resource_name}":
          command => "pcs constraint remove ${old_order_constraint}",
          onlyif  => "pcs constraint order --full | egrep -q 'id:${old_order_constraint}'",
          tries   => $pcs_tries,
          path    => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
          tag     => 'ovn_dbs_remove_old_cruft',
        }
        $old_colocation_constraint = "colocation-${old_vip_name}-ovn-dbs-bundle-INFINITY"
        exec { "remove-old-${old_vip_name}-colocation-${ovndb_servers_resource_name}":
          command => "pcs constraint remove ${old_colocation_constraint}",
          onlyif  => "pcs constraint colocation --full | egrep -q 'id:${old_colocation_constraint}'",
          tries   => $pcs_tries,
          path    => ['/sbin', '/usr/sbin', '/bin', '/usr/bin'],
          tag     => 'ovn_dbs_remove_old_cruft',
        }
      }
      # End of constraint removal section

      Pcmk_bundle<| title == 'ovn-dbs-bundle' |>
      -> Pcmk_resource<| title == "${ovndb_servers_resource_name}" |>
        -> Pcmk_resource<| title == "${ovndb_vip_resource_name}" |>
          -> Pcmk_constraint<| title == "${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}" |>
            -> Pcmk_constraint<| title == "${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}" |>
    }
  }
}
