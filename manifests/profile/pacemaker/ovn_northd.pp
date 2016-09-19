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
# [*pacemaker_master*]
#   (Optional) The hostname of the pacemaker master
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
#   (Optional) The OVN database virtual IP to be managed by the pacemaker.
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

class tripleo::profile::pacemaker::ovn_northd (
  $pacemaker_master = hiera('ovn_dbs_short_bootstrap_node_name'),
  $step             = hiera('step'),
  $pcs_tries        = hiera('pcs_tries', 20),
  $ovn_dbs_vip      = hiera('ovn_dbs_vip'),
  $nb_db_port       = 6641,
  $sb_db_port       = 6642
) {

  if $step >= 2 {
      pacemaker::property { 'ovndb-role-node-property':
      property => 'ovndb-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
  }

  if $step >= 3 and downcase($::hostname) == $pacemaker_master {
    $ovndb_servers_resource_name = 'ovndb_servers'
    $ovndb_servers_ocf_name      = 'ovn:ovndb-servers'
    $ovndb_vip_resource_name     = "ip-${ovn_dbs_vip}"

    if is_ipv6_address($ovn_dbs_vip) {
      $netmask = '128'
      $nic     = interface_for_ip($ovn_dbs_vip)
    } else {
      $netmask = '32'
      $nic     = ''
    }

    pacemaker::resource::ip { "${ovndb_vip_resource_name}":
      ip_address   => $ovn_dbs_vip,
      cidr_netmask => $netmask,
      nic          => $nic,
      tries        => $pcs_tries,
    }

    pacemaker::resource::ocf { "${ovndb_servers_resource_name}":
      ocf_agent_name  => "${ovndb_servers_ocf_name}",
      master_params   => '',
      op_params       => 'start timeout=200s stop timeout=200s',
      resource_params => "master_ip=${ovn_dbs_vip} nb_master_port=${nb_db_port} sb_master_port=${sb_db_port} manage_northd=yes",
      tries           => $pcs_tries,
      location_rule   => {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['ovndb-role eq true'],
      },
      meta_params     => 'notify=true'
    }

    pacemaker::constraint::order { "${ovndb_vip_resource_name}-then-${ovndb_servers_resource_name}":
      first_resource    => "${ovndb_vip_resource_name}",
      second_resource   => "${ovndb_servers_resource_name}-master",
      first_action      => 'start',
      second_action     => 'start',
      constraint_params => 'kind=Mandatory',
      tries             => $pcs_tries,
    }

    pacemaker::constraint::colocation { "${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}":
      source       => "${ovndb_vip_resource_name}",
      target       => "${ovndb_servers_resource_name}-master",
      master_slave => true,
      score        => 'INFINITY',
      tries        => $pcs_tries,
    }

    Pacemaker::Resource::Ip["${ovndb_vip_resource_name}"] ->
      Pacemaker::Resource::Ocf["${ovndb_servers_resource_name}"] ->
        Pacemaker::Constraint::Order["${ovndb_vip_resource_name}-then-${ovndb_servers_resource_name}"] ->
          Pacemaker::Constraint::Colocation["${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}"]
  }
}
