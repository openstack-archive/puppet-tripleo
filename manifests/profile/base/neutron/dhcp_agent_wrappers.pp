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
# == Class: tripleo::profile::base::neutron::dhcp_agent_wrappers
#
# Generates wrapper scripts for running dhcp agent subprocesess in containers.
#
# === Parameters
#
# [*enable_dnsmasq_wrapper*]
#  (Optional) If true, generates a wrapper for running dnsmasq in a container.
#  Defaults to false
#
# [*dnsmasq_process_wrapper*]
#   (Optional) Filename for dnsmasq wrapper in the specified file.
#   Defaults to undef
#
# [*dnsmasq_image*]
#   (Optional) Container image name for dnsmasq. Required if
#   dnsmasq_process_wrapper is set.
#   Defaults to undef
#
# [*enable_haproxy_wrapper*]
#  (Optional) If true, generates a wrapper for running haproxy in a container.
#  Defaults to false
#
# [*haproxy_process_wrapper*]
#   (Optional) If set, generates a haproxy wrapper in the specified file.
#   Defaults to undef
#
# [*haproxy_image*]
#   (Optional) Container image name for haproxy. Required if
#   haproxy_process_wrapper is set.
#   Defaults to undef
#
# [*debug*]
#   (Optional) Debug messages for the wrapper scripts.
#   Defaults to False.
#
class tripleo::profile::base::neutron::dhcp_agent_wrappers (
  $enable_dnsmasq_wrapper  = false,
  $dnsmasq_process_wrapper = undef,
  $dnsmasq_image           = undef,
  $enable_haproxy_wrapper  = false,
  $haproxy_process_wrapper = undef,
  $haproxy_image           = undef,
  Boolean $debug           = false,
) {
  $container_cli = lookup('tripleo::profile::base::neutron::container_cli', undef, undef, 'podman')
  if $enable_dnsmasq_wrapper {
    unless $dnsmasq_image and $dnsmasq_process_wrapper{
      fail('The container image for dnsmasq and wrapper filename must be provided when generating dnsmasq wrappers')
    }
    tripleo::profile::base::neutron::wrappers::dnsmasq{'dhcp_dnsmasq_process_wrapper':
      dnsmasq_process_wrapper => $dnsmasq_process_wrapper,
      dnsmasq_image           => $dnsmasq_image,
      debug                   => $debug,
      container_cli           => $container_cli,
    }
  }

  if $enable_haproxy_wrapper {
    unless $haproxy_image and $haproxy_process_wrapper{
      fail('The container image for haproxy and wrapper filename must be provided when generating haproxy wrappers')
    }
    tripleo::profile::base::neutron::wrappers::haproxy{'dhcp_haproxy_process_wrapper':
      haproxy_process_wrapper => $haproxy_process_wrapper,
      haproxy_image           => $haproxy_image,
      debug                   => $debug,
      container_cli           => $container_cli,
    }
  }
}
