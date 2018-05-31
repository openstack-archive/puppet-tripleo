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
# == Class: tripleo::profile::base::neutron::l3_agent_wrappers
#
# Generates wrapper scripts for running l3 agent subprocesess in containers.
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
# [*enable_radvd_wrapper*]
#  (Optional) If true, generates a wrapper for running radvd in
#  a docker container.
#  Defaults to false
#
# [*radvd_process_wrapper*]
#   (Optional) If set, generates a radvd wrapper in the specified file.
#   Defaults to undef
#
# [*radvd_image*]
#   (Optional) Docker image name for haproxy. Required if radvd_process_wrapper
#   is set.
#   Defaults to undef
#
# [*enable_keepalived_wrapper*]
#  (Optional) If true, generates a wrapper for running keepalived in
#  a docker container.
#  Defaults to false
#
# [*keepalived_process_wrapper*]
#   (Optional) If set, generates a keepalived in the specified file.
#   Defaults to undef
#
# [*keepalived_image*]
#   (Optional) Docker image name for keepalived. Required if
#   keepalived_process_wrapper is set.
#   Defaults to undef
#
# [*keepalived_state_change_wrapper*]
#   (Optional) If set, generates a wrapper for running neutron's keepalived
#   state change daemon in the keepalived container. The keepalived wrapper and
#   image must also be set if this is set.
#   Defaults to undef
#
# [*enable_dibbler_wrapper*]
#  (Optional) If true, generates a wrapper for running dibbler in
#  a docker container.
#  Defaults to false
#
# [*dibbler_process_wrapper*]
#   (Optional) If set, generates a dibbler in the specified file.
#   Defaults to undef
#
# [*dibbler_image*]
#   (Optional) Docker image name for dibbler. Required if dibbler_process_wrapper is set.
#   Defaults to undef
#
# [*bind_sockets*]
#   (Optional) Domain sockets that the wrappers should use for accessing
#   the docker daemon.
#   Defaults to hiera('docker_additional_sockets', ['/var/lib/openstack/docker.sock'])
#
class tripleo::profile::base::neutron::l3_agent_wrappers (
  $enable_haproxy_wrapper             = false,
  $haproxy_process_wrapper            = undef,
  $haproxy_image                      = undef,
  $enable_radvd_wrapper               = false,
  $radvd_process_wrapper              = undef,
  $radvd_image                        = undef,
  $enable_keepalived_wrapper          = false,
  $keepalived_process_wrapper         = undef,
  $keepalived_image                   = undef,
  $keepalived_state_change_wrapper    = undef,
  $enable_dibbler_wrapper             = false,
  $dibbler_process_wrapper            = undef,
  $dibbler_image                      = undef,
  $bind_sockets                       = hiera('docker_additional_sockets', ['/var/lib/openstack/docker.sock']),
) {
  unless $bind_sockets {
    fail('The wrappers require a domain socket for accessing the docker daemon')
  }
  $bind_socket = join(['unix://', $bind_sockets[0]], '')
  if $enable_haproxy_wrapper {
    unless $haproxy_image and $haproxy_process_wrapper{
      fail('The docker image for haproxy and wrapper filename must be provided when generating haproxy wrappers')
    }
    tripleo::profile::base::neutron::wrappers::haproxy{'l3_haproxy_process_wrapper':
      haproxy_process_wrapper => $haproxy_process_wrapper,
      haproxy_image           => $haproxy_image,
      bind_socket             => $bind_socket,
    }
  }

  if $enable_radvd_wrapper {
    unless $radvd_image and $radvd_process_wrapper{
      fail('The docker image for radvd and wrapper filename must be provided when generating radvd wrappers')
    }
    tripleo::profile::base::neutron::wrappers::radvd{'l3_radvd_process_wrapper':
      radvd_process_wrapper => $radvd_process_wrapper,
      radvd_image           => $radvd_image,
      bind_socket           => $bind_socket,
    }
  }

  if $enable_keepalived_wrapper {
    unless $keepalived_image and $keepalived_process_wrapper{
      fail('The docker image for keepalived and wrapper filename must be provided when generating keepalived wrappers')
    }
    tripleo::profile::base::neutron::wrappers::keepalived{'l3_keepalived':
      keepalived_process_wrapper => $keepalived_process_wrapper,
      keepalived_image           => $keepalived_image,
      bind_socket                => $bind_socket,
    }
    unless $keepalived_state_change_wrapper {
      fail('The keepalived state change wrapper must also be configured when generating keepalived wrappers')
    }
    tripleo::profile::base::neutron::wrappers::keepalived_state_change{'l3_keepalived_state_change':
      keepalived_state_change_wrapper => $keepalived_state_change_wrapper,
      bind_socket                     => $bind_socket,
    }
  }

  if $enable_dibbler_wrapper {
    unless $dibbler_image and $dibbler_process_wrapper{
      fail('The docker image for dibbler and wrapper filename must be provided when generating dibbler wrappers')
    }
    tripleo::profile::base::neutron::wrappers::dibbler_client{'l3_dibbler_daemon':
      dibbler_process_wrapper => $dibbler_process_wrapper,
      dibbler_image           => $dibbler_image,
      bind_socket             => $bind_socket,
    }
  }
}
