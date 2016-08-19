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
# == Class: tripleo::profile::base::pacemaker
#
# Pacemaker profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::pacemaker (
  $step = hiera('step'),
) {
  Pcmk_resource <| |> {
    tries     => 10,
    try_sleep => 3,
  }

  if $::hostname == downcase(hiera('bootstrap_nodeid')) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  $enable_fencing = str2bool(hiera('enable_fencing', false)) and $step >= 5

  if $step >= 1 {
    $pacemaker_cluster_members = downcase(regsubst(hiera('controller_node_names'), ',', ' ', 'G'))
    $corosync_ipv6 = str2bool(hiera('corosync_ipv6', false))
    if $corosync_ipv6 {
      $cluster_setup_extras = { '--token' => hiera('corosync_token_timeout', 1000), '--ipv6' => '' }
    } else {
      $cluster_setup_extras = { '--token' => hiera('corosync_token_timeout', 1000) }
    }
    class { '::pacemaker':
      hacluster_pwd => hiera('hacluster_pwd'),
    } ->
    class { '::pacemaker::corosync':
      cluster_members      => $pacemaker_cluster_members,
      setup_cluster        => $pacemaker_master,
      cluster_setup_extras => $cluster_setup_extras,
    }
    class { '::pacemaker::stonith':
      disable => !$enable_fencing,
    }
    if $enable_fencing {
      include ::tripleo::fencing

      # enable stonith after all Pacemaker resources have been created
      Pcmk_resource<||> -> Class['tripleo::fencing']
      Pcmk_constraint<||> -> Class['tripleo::fencing']
      Exec <| tag == 'pacemaker_constraint' |> -> Class['tripleo::fencing']
      # enable stonith after all fencing devices have been created
      Class['tripleo::fencing'] -> Class['pacemaker::stonith']
    }

    # FIXME(gfidente): sets 200secs as default start timeout op
    # param; until we can use pcmk global defaults we'll still
    # need to add it to every resource which redefines op params
    Pacemaker::Resource::Service {
      op_params => 'start timeout=200s stop timeout=200s',
    }

    file { '/var/lib/tripleo/pacemaker-restarts':
      ensure => directory,
    } ~> Tripleo::Pacemaker::Resource_restart_flag<||>
  }

  if $step >= 2 {
    if $pacemaker_master {
      include ::pacemaker::resource_defaults
    }
  }

}
