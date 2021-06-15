# Copyright 2020 Red Hat, Inc.
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
# == define: tripleo::profile::base::nova::wrappers::virtlogd
#
# Generates wrapper script for running virtlogd in a container.
#
# === Parameters
#
# [*virtlogd_process_wrapper*]
#   Filename for virtlogd wrapper script.
#
# [*virtlogd_image*]
#   Docker image name for virtlogd.
#
# [*debug*]
#   Enable debug messages for the wrapper script.
#
define tripleo::profile::base::nova::wrappers::virtlogd (
  $virtlogd_process_wrapper,
  $virtlogd_image,
  Boolean $debug,
) {
    file { $virtlogd_process_wrapper:
      ensure  => file,
      mode    => '0755',
      content => epp('tripleo/nova/virtlogd.epp', {
        'image_name' => $virtlogd_image,
        'debug'      => $debug,
        })
    }
}
