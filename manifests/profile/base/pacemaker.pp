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
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*remote_short_node_names*]
#   (Optional) List of short node names for pacemaker remote nodes
#   Defaults to hiera('pacemaker_remote_short_node_names', [])
#
# [*remote_node_ips*]
#   (Optional) List of node ips for pacemaker remote nodes
#   Defaults to hiera('pacemaker_remote_node_ips', [])
#
# [*remote_authkey*]
#   (Optional) Authkey for pacemaker remote nodes
#   Defaults to undef
#
# [*remote_reconnect_interval*]
#   (Optional) Reconnect interval for the remote
#   Defaults to hiera('pacemaker_remote_reconnect_interval', 60)
#
# [*remote_monitor_interval*]
#   (Optional) Monitor interval for the remote
#   Defaults to hiera('pacemaker_monitor_reconnect_interval', 20)
#
# [*remote_tries*]
#   (Optional) Number of tries for the remote resource creation
#   Defaults to hiera('pacemaker_remote_tries', 5)
#
# [*remote_try_sleep*]
#   (Optional) Number of seconds to sleep between remote creation tries
#   Defaults to hiera('pacemaker_remote_try_sleep', 60)
#
# [*cluster_recheck_interval*]
#   (Optional) Set the cluster-wide cluster-recheck-interval property
#   If the hiera key does not exist or if it is set to undef, the property
#   won't be changed from its default value when there are no pacemaker_remote
#   nodes. In presence of pacemaker_remote nodes and an undef value it will
#   be set to 60s.
#   Defaults to hiera('pacemaker_cluster_recheck_interval', undef)
#
# [*encryption*]
#   (Optional) Whether or not to enable encryption of the pacemaker traffic
#   Defaults to true
#
# [*enable_instanceha*]
#  (Optional) Boolean driving the Instance HA controlplane configuration
#  Defaults to false
#
class tripleo::profile::base::pacemaker (
  $step                      = Integer(hiera('step')),
  $pcs_tries                 = hiera('pcs_tries', 20),
  $remote_short_node_names   = hiera('pacemaker_remote_short_node_names', []),
  $remote_node_ips           = hiera('pacemaker_remote_node_ips', []),
  $remote_authkey            = undef,
  $remote_reconnect_interval = hiera('pacemaker_remote_reconnect_interval', 60),
  $remote_monitor_interval   = hiera('pacemaker_remote_monitor_interval', 20),
  $remote_tries              = hiera('pacemaker_remote_tries', 5),
  $remote_try_sleep          = hiera('pacemaker_remote_try_sleep', 60),
  $cluster_recheck_interval  = hiera('pacemaker_cluster_recheck_interval', undef),
  $encryption                = true,
  $enable_instanceha         = hiera('tripleo::instanceha', false),
) {

  if count($remote_short_node_names) != count($remote_node_ips) {
    fail("Count of ${remote_short_node_names} is not equal to count of ${remote_node_ips}")
  }

  if hiera('hacluster_pwd', undef) == undef {
    fail("The 'hacluster_pwd' hiera key is undefined, did you forget to include ::tripleo::profile::base::pacemaker in your role?")
  }

  Pcmk_resource <| |> {
    tries     => 10,
    try_sleep => 3,
  }

  if $::hostname == downcase(hiera('pacemaker_short_bootstrap_node_name')) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  $enable_fencing = str2bool(hiera('enable_fencing', false)) and $step >= 5

  if $step >= 1 {
    $pacemaker_short_node_names = join(hiera('pacemaker_short_node_names'), ',')
    $pacemaker_cluster_members = downcase(regsubst($pacemaker_short_node_names, ',', ' ', 'G'))
    $corosync_ipv6 = str2bool(hiera('corosync_ipv6', false))
    if $corosync_ipv6 {
      $cluster_setup_extras_pre = {
        '--token' => hiera('corosync_token_timeout', 1000),
        '--ipv6' => ''
      }
    } else {
      $cluster_setup_extras_pre = {
        '--token' => hiera('corosync_token_timeout', 1000)
      }
    }

    if $encryption {
      $cluster_setup_extras = merge($cluster_setup_extras_pre, {'--encryption' => '1'})
    } else {
      $cluster_setup_extras = $cluster_setup_extras_pre
    }
    class { '::pacemaker':
      hacluster_pwd => hiera('hacluster_pwd'),
    }
    -> class { '::pacemaker::corosync':
      cluster_members      => $pacemaker_cluster_members,
      setup_cluster        => $pacemaker_master,
      cluster_setup_extras => $cluster_setup_extras,
      remote_authkey       => $remote_authkey,
    }
    if str2bool(hiera('docker_enabled', false)) {
      include ::systemd::systemctl::daemon_reload

      Package<| name == 'docker' |>
      -> file { '/etc/systemd/system/resource-agents-deps.target.wants':
        ensure => directory,
      }
      -> systemd::unit_file { 'docker.service':
        path   => '/etc/systemd/system/resource-agents-deps.target.wants',
        target => '/usr/lib/systemd/system/docker.service',
        before => Class['pacemaker'],
      }
      ~> Class['systemd::systemctl::daemon_reload']
    }

    if $pacemaker_master {
      class { '::pacemaker::stonith':
        disable => !$enable_fencing,
        tries   => $pcs_tries,
      }
    }
    if $enable_fencing {
      include ::tripleo::fencing

      # enable stonith after all Pacemaker resources have been created
      Pcmk_resource<||> -> Class['tripleo::fencing']
      Pcmk_constraint<||> -> Class['tripleo::fencing']
      Exec <| tag == 'pacemaker_constraint' |> -> Class['tripleo::fencing']
      # enable stonith after all fencing devices have been created
      Class['tripleo::fencing'] -> Pcmk_property<|title == 'Enable STONITH'|>
    }
    # We have pacemaker remote nodes configured so let's add them as resources
    # We do this during step 1 right after wait-for-settle, because during step 2
    # resources might already be created on pacemaker remote nodes and we need
    # a guarantee that remote nodes are already up
    if $pacemaker_master and count($remote_short_node_names) > 0 {
      # Creates a { "node" => "ip_address", ...} hash
      $remotes_hash = hash(zip($remote_short_node_names, $remote_node_ips))
      $remote_short_node_names.each |String $remote_short_node| {
        pacemaker::resource::remote { $remote_short_node:
          remote_address     => $remotes_hash[$remote_short_node],
          reconnect_interval => $remote_reconnect_interval,
          op_params          => "monitor interval=${remote_monitor_interval}",
          tries              => $remote_tries,
          try_sleep          => $remote_try_sleep,
          before             => Exec["exec-wait-for-${remote_short_node}"],
          notify             => Exec["exec-wait-for-${remote_short_node}"],
        }
        $check_command = "pcs status | grep -q -e \"${remote_short_node}.*Started\""
        exec { "exec-wait-for-${remote_short_node}":
          path      => '/usr/sbin:/usr/bin:/sbin:/bin',
          command   => $check_command,
          unless    => $check_command,
          timeout   => 30,
          tries     => 180,
          try_sleep => 10,
          tag       => 'remote_ready',
        }
      }
    }
  }

  if $enable_instanceha and $pacemaker_master {
    include ::tripleo::profile::base::pacemaker::instance_ha
  }

  if ($step >= 2 and $pacemaker_master) {
    if ! $enable_instanceha {
      include ::pacemaker::resource_defaults
    }
    # When we have a non-zero number of pacemaker remote nodes we
    # want to set the cluster-recheck-interval property to something
    # lower (unless the operator has explicitely set a value)
    if count($remote_short_node_names) > 0 and $cluster_recheck_interval == undef {
      pacemaker::property{ 'cluster-recheck-interval-property':
        property => 'cluster-recheck-interval',
        value    => '60s',
        tries    => $pcs_tries,
      }
    } elsif $cluster_recheck_interval != undef {
      pacemaker::property{ 'cluster-recheck-interval-property':
        property => 'cluster-recheck-interval',
        value    => $cluster_recheck_interval,
        tries    => $pcs_tries,
      }
    }
  }
}
