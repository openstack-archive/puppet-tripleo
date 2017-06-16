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
# == Class: tripleo::profile::pacemaker::ceph::rbdmirror
#
# Ceph RBD mirror Pacemaker profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('ceph_rbdmirror_bootstrap_short_node_name')
#
# [*client_name*]
#   (Optional) Name assigned to the RBD mirror client
#   Defaults to 'rbd-mirror'
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*stack_action*]
#   (Optional) Action executed on the stack. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('stack_action')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::ceph::rbdmirror (
  $bootstrap_node = hiera('ceph_rbdmirror_short_bootstrap_node_name'),
  $client_name    = 'openstack',
  $pcs_tries      = hiera('pcs_tries', 20),
  $stack_action   = hiera('stack_action'),
  $step           = Integer(hiera('step')),
) {
  Service <| tag == 'ceph-rbd-mirror' |> {
    hasrestart => true,
    restart    => '/bin/true',
    start      => '/bin/true',
    stop       => '/bin/true',
  }

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::ceph

  if $step >= 2 {
    pacemaker::property { 'ceph-rbdmirror-role-node-property':
      property => 'ceph-rbdmirror-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
  }

  if $step >= 3 {
    require ::ceph::profile::client
    ceph::mirror { $client_name:
      rbd_mirror_enable => false,
      rbd_mirror_ensure => 'stopped',
    } ->
    pacemaker::resource::service { "ceph-rbd-mirror_${client_name}":
      # NOTE(gfidente): systemd uses the @ sign but it is an invalid
      # character in a pcmk resource name, so we need to use it only
      # for the name of the service
      service_name  => "ceph-rbd-mirror@${client_name}",
      tries         => $pcs_tries,
      location_rule => {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['ceph-rbdmirror-role eq true'],
      }
    }
  }

  if $step >= 3 and $pacemaker_master and $stack_action == 'UPDATE' {
    Ceph_config<||> ~> Tripleo::Pacemaker::Resource_restart_flag["ceph-rbd-mirror@${client_name}"]
    tripleo::pacemaker::resource_restart_flag { "ceph-rbd-mirror@${client_name}": }
  }
}
