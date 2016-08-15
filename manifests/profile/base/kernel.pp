# Copyright 2016 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::kernel
#
# Load and configure Kernel modules.
#
class tripleo::profile::base::kernel {

  if hiera('kernel_modules', undef) {
    create_resources(kmod::load, hiera('kernel_modules'), { })
  }
  if hiera('sysctl_settings', undef) {
    create_resources(sysctl::value, hiera('sysctl_settings'), { })
  }
  Exec <| tag == 'kmod::load' |> -> Sysctl <| |>

}
