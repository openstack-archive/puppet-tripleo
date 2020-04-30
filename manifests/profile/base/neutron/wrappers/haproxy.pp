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
# == define: tripleo::profile::base::neutron::wrappers::haproxy
#
# Generates wrapper script for running haproxy in a container.
#
# === Parameters
#
# [*haproxy_process_wrapper*]
#   Filename for haproxy wrapper script.
#
# [*haproxy_image*]
#   Docker image name for haproxy.
#
# [*bind_socket*]
#   Socket for accessing the docker daemon.
#
# [*debug*]
#   Enable debug messages for the wrapper script.
#
# [*container_cli*]
#   Host containers runtime system to use.
#
define tripleo::profile::base::neutron::wrappers::haproxy (
  $haproxy_process_wrapper,
  $haproxy_image,
  Boolean $debug,
  $container_cli,
  $bind_socket = undef,
) {
    file { $haproxy_process_wrapper:
      ensure  => file,
      mode    => '0755',
      content => epp('tripleo/neutron/haproxy.epp', {
        'image_name'    => $haproxy_image,
        'bind_socket'   => $bind_socket,
        'debug'         => $debug,
        'container_cli' => $container_cli,
        })
    }
}
