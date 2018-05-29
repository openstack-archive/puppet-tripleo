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
# == Class: tripleo::profile::base::neutron::ovn_metadata_agent_wrappers
#
# Generates wrapper scripts for running OVN metadata agent subprocesess in containers.
#
# === Parameters
#
# [*enable_haproxy_wrapper*]
#  (Optional) If true, generates a wrapper for running haproxy in
#  a docker container.
#  Defaults to false
#
# [*haproxy_process_wrapper*]
#   (Optional) If set, generates a haproxy wrapper in the specified file.
#   Defaults to undef
#
# [*haproxy_image*]
#   (Optional) Docker image name for haproxy. Required if
#   haproxy_process_wrapper is set.
#   Defaults to undef
#
# [*bind_sockets*]
#   (Optional) Domain sockets that the wrappers should use for accessing
#   the docker daemon.
#   Defaults to hiera('docker_additional_sockets', ['/var/lib/openstack/docker.sock'])
#
class tripleo::profile::base::neutron::ovn_metadata_agent_wrappers (
  $enable_haproxy_wrapper    = false,
  $haproxy_process_wrapper   = undef,
  $haproxy_image             = undef,
  $bind_sockets              = hiera('docker_additional_sockets', ['/var/lib/openstack/docker.sock']),
) {
  unless $bind_sockets {
    fail('The wrappers require a domain socket for accessing the docker daemon')
  }
  $bind_socket = join(['unix://', $bind_sockets[0]], '')
  if $enable_haproxy_wrapper {
    unless $haproxy_image and $haproxy_process_wrapper{
      fail('The docker image for haproxy and wrapper filename must be provided when generating haproxy wrappers')
    }
    tripleo::profile::base::neutron::wrappers::haproxy{'ovn_metadata_haproxy_process_wrapper':
      haproxy_process_wrapper => $haproxy_process_wrapper,
      haproxy_image           => $haproxy_image,
      bind_socket             => $bind_socket
    }
  }
}
