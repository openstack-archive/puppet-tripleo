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
# == Class: tripleo::profile::pacemaker::ceph_nfs
#
# Ganesha Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('manila_share_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
class tripleo::profile::pacemaker::ceph_nfs (
  $bootstrap_node          = hiera('manila_share_short_bootstrap_node_name'),
  $step                    = hiera('step'),
  $pcs_tries               = hiera('pcs_tries', 20),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  $ganesha_vip = hiera('ganesha_vip')
  # NB: Until the IPaddr2 RA has a fix for https://bugzilla.redhat.com/show_bug.cgi?id=1445628
  # we need to specify the nic when creating the ipv6 vip.
  if is_ipv6_address($ganesha_vip) {
    $netmask        = '128'
    $nic            = interface_for_ip($ganesha_vip)
    $ipv6_addrlabel = '99'
  } else {
    $netmask        = '32'
    $nic            = ''
    $ipv6_addrlabel = ''
  }


  Service <| tag == 'ceph-nfs' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  if $step >= 2 {
    pacemaker::property { 'ceph-nfs-role-node-property':
      property => 'ceph-nfs-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
    if $pacemaker_master {
      pacemaker::resource::ip { 'ganesha_vip':
        ip_address    => $ganesha_vip,
        cidr_netmask  => $netmask,
        nic           => $nic,
        #ipv6_addrlabel => $ipv6_addrlabel,
        #ipv6_addrlabel => '',
        tries         => $pcs_tries,
        location_rule => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['ceph-nfs-role eq true'],
        },
      }
    }
  }

  if $step >= 5 and $pacemaker_master {
    pacemaker::resource::service { 'ceph-nfs' :
      service_name  => 'ceph-nfs@pacemaker',
      op_params     => 'start timeout=200s stop timeout=200s',
      tries         => $pcs_tries,
      location_rule => {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['ceph-nfs-role eq true'],
      },
    }

    pacemaker::constraint::colocation { 'ganesha_vip-with-ganesha':
      source => "ip-${ganesha_vip}",
      target => 'ceph-nfs',
      score  => 'INFINITY',
      tries  => $pcs_tries,
    }

    pacemaker::constraint::order { 'ganesha_vip-then-ganesha':
      first_resource    => "ip-${ganesha_vip}",
      second_resource   => 'ceph-nfs',
      first_action      => 'start',
      second_action     => 'start',
      constraint_params => 'kind=Optional',
      tries             => $pcs_tries,
      tag               => 'pacemaker_constraint',
    }

    Pacemaker::Resource::Ip['ganesha_vip']
      -> Pacemaker::Resource::Service['ceph-nfs']
        -> Pacemaker::Constraint::Order['ganesha_vip-then-ganesha']
          -> Pacemaker::Constraint::Colocation['ganesha_vip-with-ganesha']
  }
}
