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
# == Define: tripleo::pacemaker::resource_restart_flag
#
# Creates a flag file on the filesystem to signify that a pacemaker
# resource needs restarting (usually to pick up config changes after
# they've been written on all nodes).
#
# === Parameters
#
# [*title*]
#   The resource name in Pacemaker to restart. If it's a cloned
#   resource, the name should include the '-clone' part.
#
define tripleo::pacemaker::resource_restart_flag() {

  ensure_resource('file', ['/var/lib/tripleo', '/var/lib/tripleo/pacemaker-restarts'],
    {
      'ensure' => 'directory',
      'owner'  => 'root',
      'mode'   => '0755',
      'group'  => 'root',
    }
  )

  exec { "${title} resource restart flag":
    command     => "touch /var/lib/tripleo/pacemaker-restarts/${title}",
    path        => ['/bin','/usr/bin','/sbin','/usr/sbin'],
    refreshonly => true,
  }

  File['/var/lib/tripleo/pacemaker-restarts']
  -> Exec["${title} resource restart flag"]
}
