# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::lvm
#
# LVM profile for tripleo
#
# === Parameters
#
# [*enable_udev*]
#   (Optional) Whether to enable udev usage by LVM.
#   Defaults to true
#
class tripleo::profile::base::lvm (
  $enable_udev        = true,
) {

  if $enable_udev {
    $udev_options_value = 1
  } else {
    $udev_options_value = 0
  }
  augeas {'udev options in lvm.conf':
    context => '/files/etc/lvm/lvm.conf/activation/dict/',
    changes => ["set udev_sync/int ${udev_options_value}",
                "set udev_rules/int ${udev_options_value}"],
  }

}
