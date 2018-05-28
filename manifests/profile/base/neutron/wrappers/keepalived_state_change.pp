# Copyright 2018 Red Hat, Inc.
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
# == Class: tripleo::profile::base::neutron::wrappers::keepalived_state_change
#
# Generates wrapper script for running keepalived-state-change daemon in a container.
#
# === Parameters
#
# [*keepalived_state_change_wrapper*]
#   Filename for neutron-keepalived-state-change wrapper script.
#
# [*bind_socket*]
#   Socket for accessing the docker daemon.
#
define tripleo::profile::base::neutron::wrappers::keepalived_state_change (
  $keepalived_state_change_wrapper,
  $bind_socket,
) {
    file { $keepalived_state_change_wrapper:
      ensure  => file,
      mode    => '0755',
      content => epp('tripleo/neutron/neutron-keepalived-state-change.epp', {
        'bind_socket' => $bind_socket
        })
    }
}
