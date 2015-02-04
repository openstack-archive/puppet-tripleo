# Copyright 2015 Red Hat, Inc.
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

# == Class: tripleo::packages
#
# A class that effectively disables distro package installation.
#
# === Parameters:
#
# [*disable_package_install*]
#   Defaults to false. Set to true to disable package installation.
class tripleo::package_provider (
  $disable_package_install = false,
) {

  if $disable_package_install {
    case $::osfamily {
      'RedHat': {
        Package { provider => 'norpm' }
      }
      default: {
        warning('tripleo::packages does not support this distribution.')
      }
    }
  }

}
