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
# == define: tripleo::profile::base::neutron::wrappers::dnsmasq
#
# Generates wrapper script for running dnsmasq in a container.
#
# === Parameters
#
# [*dnsmasq_process_wrapper*]
#   Filename for dnsmasq wrapper script.
#
# [*dnsmasq_image*]
#   Docker image name for dnsmasq.
#
# [*bind_socket*]
#   Socket for accessing the docker daemon.
#
define tripleo::profile::base::neutron::wrappers::dnsmasq (
  $dnsmasq_process_wrapper,
  $dnsmasq_image,
  $bind_socket,
) {
    file { $dnsmasq_process_wrapper:
      ensure  => file,
      mode    => '0755',
      content => epp('tripleo/neutron/dnsmasq.epp', {
        'image_name'  => $dnsmasq_image,
        'bind_socket' => $bind_socket
        })
    }
}
