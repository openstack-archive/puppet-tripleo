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
# == Class: tripleo::profile::base::nova::virtlogd_wrapper
#
# Generates wrapper scripts for running virtlogd in container.
#
# === Parameters
#
# [*enable_wrapper*]
#  (Optional) If true, generates a wrapper for running virtlogd in
#  a docker container.
#  Defaults to false
#
# [*virtlogd_process_wrapper*]
#   (Optional) Filename for virtlogd wrapper in the specified file.
#   Defaults to undef
#
# [*virtlogd_image*]
#   (Optional) Docker image name for virtlogd. Required if
#   virtlogd_wrapper is set.
#   Defaults to undef
#
# [*debug*]
#   (Optional) Debug messages for the wrapper scripts.
#   Defaults to False.
#
class tripleo::profile::base::nova::virtlogd_wrapper (
  $enable_wrapper           = false,
  $virtlogd_process_wrapper = undef,
  $virtlogd_image           = undef,
  Boolean $debug            = false,
) {
  if $enable_wrapper {
    unless $virtlogd_image and $virtlogd_process_wrapper{
      fail('The docker image for virtlogd and wrapper filename must be provided when generating virtlogd wrappers')
    }
    tripleo::profile::base::nova::wrappers::virtlogd{'nova_virtlogd_wrapper':
      virtlogd_process_wrapper => $virtlogd_process_wrapper,
      virtlogd_image           => $virtlogd_image,
      debug                    => $debug,
    }
  }
}
