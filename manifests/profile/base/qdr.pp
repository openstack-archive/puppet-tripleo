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
# == Class: tripleo::profile::base::qdr
#
# Qpid dispatch router profile for tripleo
#
# === Parameters
#
# [*qdr_username*]
#   Username for the qrouter daemon
#   Defaults to undef
#
# [*qdr_password*]
#   Password for the qrouter daemon
#   Defaults to undef
#
# [*qdr_listener_port*]
#   Port for the listener (not that we do not use qdr::listener_port
#   directly because it requires a string and we have a number.
#   Defaults to hiera('tripleo::profile::base::qdr::qdr_listener_port', 5672)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::qdr (
  $qdr_username      = undef,
  $qdr_password      = undef,
  $qdr_listener_port = hiera('tripleo::profile::base::qdr::qdr_listener_port', 5672),
  $step              = Integer(hiera('step')),
) {
  if $step >= 1 {
    class { '::qdr':
      listener_port => "${qdr_listener_port}",
    } ->
    qdr_user { $qdr_username:
      ensure   => present,
      password => $qdr_password,
    }
  }
}
