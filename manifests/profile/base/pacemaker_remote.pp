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
# [*pcs_user*]
#   (Optional) The user to set up pcsd with
#   Defaults to 'hacluster'
#
# [*pcs_password*]
#   (Optional) The password to be used for the pcs_user. While it is
#   optional as a parameter, the hiera key 'hacluster_pwd' *must* not
#   be undefined or an error will be generated.
#   Defaults to hiera('hacluster_pwd', undef)
#
# [*enable_fencing*]
#   (Optional) Whether or not to manage stonith devices for nodes
#   Defaults to hiera('enable_fencing', false)
#
# [*pcsd_bind_addr*]
#   (Optional) List of IP addresses pcsd should bind to
#   Defaults to undef
#
# [*tls_priorities*]
#   (optional) Sets PCMK_tls_priorities in /etc/sysconfig/pacemaker when set
#   Defaults to hiera('tripleo::pacemaker::tls_priorities', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::pacemaker_remote (
  $remote_authkey,
  $pcs_tries      = hiera('pcs_tries', 20),
  $pcs_user       = 'hacluster',
  $pcs_password   = hiera('hacluster_pwd', undef),
  $enable_fencing = hiera('enable_fencing', false),
  $pcsd_bind_addr = undef,
  $tls_priorities = hiera('tripleo::pacemaker::tls_priorities', undef),
  $step           = Integer(hiera('step')),
) {
  if $pcs_password == undef {
    fail('The $pcs_password param is and the hiera key "hacluster_pwd" hiera key are both undefined, this is not allowed')
  }
  # During FFU when override keys are set we need to use the old authkey style
  # This should be kept until FFU from CentOS 7->8 is being supported
  if count(hiera('pacemaker_remote_node_ips_override', [])) > 0 {
    $force_authkey = true
  } else {
    $force_authkey = false
  }
  class { 'pacemaker::remote':
    pcs_user       => $pcs_user,
    pcs_password   => $pcs_password,
    remote_authkey => $remote_authkey,
    use_pcsd       => true,
    pcsd_bind_addr => $pcsd_bind_addr,
    force_authkey  => $force_authkey,
    tls_priorities => $tls_priorities,
  }
  if str2bool(hiera('docker_enabled', false)) {
    include systemd::systemctl::daemon_reload

    Package<| name == 'docker' |>
    -> file { '/etc/systemd/system/resource-agents-deps.target.wants':
      ensure => directory,
    }
    -> systemd::unit_file { 'docker.service':
      path   => '/etc/systemd/system/resource-agents-deps.target.wants',
      target => '/usr/lib/systemd/system/docker.service',
      before => Class['pacemaker::remote'],
    }
    -> systemd::unit_file { 'rhel-push-plugin.service':
      path   => '/etc/systemd/system/resource-agents-deps.target.wants',
      target => '/usr/lib/systemd/system/rhel-push-plugin.service',
      before => Class['pacemaker::remote'],
    }
    ~> Class['systemd::systemctl::daemon_reload']
  }
  $enable_fencing_real = str2bool($enable_fencing) and $step >= 5

  if $enable_fencing_real {
    include tripleo::fencing

    # enable stonith after all Pacemaker resources have been created
    Pcmk_resource<||> -> Class['tripleo::fencing']
    Pcmk_constraint<||> -> Class['tripleo::fencing']
    Exec <| tag == 'pacemaker_constraint' |> -> Class['tripleo::fencing']
  }
}
