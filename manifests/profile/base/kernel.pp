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
# === Parameters
#
# [*module_list*]
#   (Optional) List of kernel modules to load.
#   Defaults to hiera('kernel_modules')
#
# [*sysctl_settings*]
#   (Optional) List of sysctl settings to load.
#   Defaults to hiera('sysctl_settings')
#
class tripleo::profile::base::kernel (
  $module_list     = hiera('kernel_modules', undef),
  $sysctl_settings = hiera('sysctl_settings', undef),
) {

  if $module_list {
    create_resources(kmod::load, $module_list, { })
  }
  if $sysctl_settings {
    create_resources(sysctl::value, $sysctl_settings, { })
  }
  Exec <| tag == 'kmod::load' |> -> Sysctl <| |>

  # RHEL 7.4+ workaround where this functionality is built into the
  # kernel instead of being built as a module.
  # That way, we can support both 7.3 and 7.4 RHEL versions.
  # https://bugzilla.redhat.com/show_bug.cgi?id=1387537
  Exec <| title == 'modprobe nf_conntrack_proto_sctp' |> { returns => [0,1] }
}
