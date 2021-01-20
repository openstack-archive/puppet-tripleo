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
#   Defaults to hiera('ceph_nfs_short_bootstrap_node_name')
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
  $bootstrap_node          = hiera('ceph_nfs_short_bootstrap_node_name'),
  $step                    = hiera('step'),
  $pcs_tries               = hiera('pcs_tries', 20),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
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
    if $pacemaker_master {
      # At step2 we only create the node property on master so that
      # both VIP and (later at step5) ceph-nfs service can start on master
      # node only. This way we can guarantee that the VIP and ceph-nfs are
      # colocated. Later we expand the properties on all nodes where ceph_nfs
      # is supposed to run.
      pacemaker::property { 'ceph-nfs-role-node-property':
        property => 'ceph-nfs-role',
        value    => true,
        tries    => $pcs_tries,
        node     => $::hostname,
      }
      pacemaker::resource::ip { 'ganesha_vip':
        ip_address     => $ganesha_vip,
        cidr_netmask   => $netmask,
        nic            => $nic,
        ipv6_addrlabel => $ipv6_addrlabel,
        tries          => $pcs_tries,
        location_rule  => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['ceph-nfs-role eq true'],
        },
      }
    }
  }

  # When we create manila-share resource at step 5 we need the ceph-nfs pcmk resource up
  # and running. But since we moved to pcs commands invoked on host, manila-share at step5
  # gets created *before* ceph-nfs (as it is invoked via step_config vs docker_config)
  if $step >= 4 and $pacemaker_master {
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

    # See comment on pacemaker::property at step2
    if (hiera('ceph_nfs_short_node_names_override', undef)) {
      $ceph_nfs_short_node_names = hiera('ceph_nfs_short_node_names_override')
    } else {
      $ceph_nfs_short_node_names = hiera('ceph_nfs_short_node_names')
    }

    $ceph_nfs_short_node_names.each |String $node_name| {
      # We only set the properties for the non-bootstrap nodes
      # because we set the property for the bootstrap node at step 2
      # already
      if $node_name != $bootstrap_node {
        pacemaker::property { "ceph-nfs-role-${node_name}":
          property => 'ceph-nfs-role',
          value    => true,
          tries    => $pcs_tries,
          node     => $node_name,
        }
      }
    }

    Pacemaker::Resource::Ip['ganesha_vip']
      -> Pacemaker::Resource::Service['ceph-nfs']
        -> Pacemaker::Constraint::Order['ganesha_vip-then-ganesha']
          -> Pacemaker::Constraint::Colocation['ganesha_vip-with-ganesha']
            -> Pacemaker::Property<||>
  }
}
