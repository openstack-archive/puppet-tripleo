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

class tripleo::profile::pacemaker::ovn_northd (
  $pacemaker_master = hiera('ovn_dbs_short_bootstrap_node_name'),
  $step             = Integer(hiera('step')),
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

    # Allow non local bind, because all the ovsdb-server's running in the
    # cluster try to open a TCP socket on the VIP.
    ensure_resource('sysctl::value',  'net.ipv4.ip_nonlocal_bind', {
      'value'=> 1,
    })
  }

  if $step >= 3 and downcase($::hostname) == $pacemaker_master {
    $ovndb_servers_resource_name = 'ovndb_servers'
    $ovndb_servers_ocf_name      = 'ovn:ovndb-servers'
    $ovndb_vip_resource_name     = "ip-${ovn_dbs_vip}"

    # By step 3, all the VIPs would have been created.
    # After creating ovn ocf resource, colocate it with the
    # VIP - ip-${ovn_dbs_vip}.
    pacemaker::resource::ocf { "${ovndb_servers_resource_name}":
      ocf_agent_name  => "${ovndb_servers_ocf_name}",
      master_params   => '',
      op_params       => 'start timeout=200s stop timeout=200s',
      resource_params => "master_ip=${ovn_dbs_vip} nb_master_port=${nb_db_port} \
sb_master_port=${sb_db_port} manage_northd=yes inactive_probe_interval=180000",
      tries           => $pcs_tries,
      location_rule   => {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['ovndb-role eq true'],
      },
      meta_params     => 'notify=true'
    }

    pacemaker::constraint::colocation { "${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}":
      source       => "${ovndb_vip_resource_name}",
      target       => "${ovndb_servers_resource_name}-master",
      master_slave => true,
      score        => 'INFINITY',
      tries        => $pcs_tries,
    }

    Pacemaker::Resource::Ocf["${ovndb_servers_resource_name}"]
      -> Pacemaker::Constraint::Colocation["${ovndb_vip_resource_name}-with-${ovndb_servers_resource_name}"]
  }
}
