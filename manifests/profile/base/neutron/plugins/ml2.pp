# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::neutron::plugins::ml2
#
# Neutron ML2 plugin profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*mechanism_drivers*]
#   (Optional) The mechanism drivers to use with the Ml2 plugin
#   Defaults to hiera('neutron::plugins::ml2::mechanism_drivers')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plugins::ml2 (
  $bootstrap_node    = hiera('bootstrap_nodeid', undef),
  $mechanism_drivers = hiera('neutron::plugins::ml2::mechanism_drivers'),
  $step              = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include ::tripleo::profile::base::neutron

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    include ::neutron::plugins::ml2

    if 'cisco_n1kv' in $mechanism_drivers {
      include ::tripleo::profile::base::neutron::n1k
    }

    if 'cisco_ucsm' in $mechanism_drivers {
      include ::neutron::plugins::ml2::cisco::ucsm
    }

    if 'cisco_nexus'  in $mechanism_drivers {
      include ::neutron::plugins::ml2::cisco::nexus
      include ::neutron::plugins::ml2::cisco::type_nexus_vxlan
    }

    if 'bsn_ml2' in $mechanism_drivers {
      include ::neutron::plugins::ml2::bigswitch::restproxy
    }

    if ('opendaylight' in $mechanism_drivers) or ('opendaylight_v2' in $mechanism_drivers) {
      include ::tripleo::profile::base::neutron::plugins::ml2::opendaylight
    }

    if 'ovn' in $mechanism_drivers {
      include ::tripleo::profile::base::neutron::plugins::ml2::ovn
    }

    if 'fujitsu_cfab' in $mechanism_drivers {
      include ::neutron::plugins::ml2::fujitsu
      include ::neutron::plugins::ml2::fujitsu::cfab
    }

    if 'fujitsu_fossw' in $mechanism_drivers {
      include ::neutron::plugins::ml2::fujitsu
      include ::neutron::plugins::ml2::fujitsu::fossw
    }

    if 'vpp' in $mechanism_drivers {
      include ::tripleo::profile::base::neutron::plugins::ml2::vpp
    }

    if 'nuage' in $mechanism_drivers {
      include ::tripleo::profile::base::neutron::plugins::ml2::nuage
    }

    if 'cisco_vts' in $mechanism_drivers {
      include ::tripleo::profile::base::neutron::plugins::ml2::vts
    }

    if 'mlnx_sdn_assist' in  $mechanism_drivers {
      include ::neutron::plugins::ml2::mellanox
      include ::neutron::plugins::ml2::mellanox::mlnx_sdn_assist
    }

    if 'baremetal' in $mechanism_drivers {
      include ::tripleo::profile::base::neutron::plugins::ml2::networking_baremetal
    }
  }
}
