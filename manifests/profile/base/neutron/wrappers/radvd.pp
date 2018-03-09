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
# == define: tripleo::profile::base::neutron::wrappers::radvd
#
# Generates wrapper script for running radvd in a container.
#
# === Parameters
#
# [*radvd_process_wrapper*]
#   Filename for radvd wrapper script.
#
# [*radvd_image*]
#   Docker image name for radvd.
#
# [*bind_socket*]
#   Socket for accessing the docker daemon.
#
define tripleo::profile::base::neutron::wrappers::radvd (
  $radvd_process_wrapper,
  $radvd_image,
  $bind_socket,
) {
    file { $radvd_process_wrapper:
      ensure  => file,
      mode    => '0755',
      content => epp('tripleo/neutron/radvd.epp', {
          'image_name'  => $radvd_image,
          'bind_socket' => $bind_socket,
        })
    }
}
