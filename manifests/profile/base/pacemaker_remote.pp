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
# == Class: tripleo::profile::base::pacemaker_remote
#
# Pacemaker remote profile for tripleo
#
# === Parameters
#
# [*remote_authkey*]
#   Authkey for pacemaker remote nodes
#   Defaults to unset
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*enable_fencing*]
#   (Optional) Whether or not to manage stonith devices for nodes
#   Defaults to hiera('enable_fencing', false)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::pacemaker_remote (
  $remote_authkey,
  $pcs_tries      = hiera('pcs_tries', 20),
  $enable_fencing = hiera('enable_fencing', false),
  $step           = Integer(hiera('step')),
) {
  class { '::pacemaker::remote':
    remote_authkey => $remote_authkey,
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
      before => Class['pacemaker::remote'],
    }
    ~> Class['systemd::systemctl::daemon_reload']
  }
  $enable_fencing_real = str2bool($enable_fencing) and $step >= 5

  if $enable_fencing_real {
    include ::tripleo::fencing

    # enable stonith after all Pacemaker resources have been created
    Pcmk_resource<||> -> Class['tripleo::fencing']
    Pcmk_constraint<||> -> Class['tripleo::fencing']
    Exec <| tag == 'pacemaker_constraint' |> -> Class['tripleo::fencing']
  }
}
