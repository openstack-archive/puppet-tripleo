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
# Configure package installation/upgrade defaults.
#
# === Parameters:
#
# [*enable_install*]
#  Whether to enable package installation via Puppet.
#  Defaults to false
#
# [*enable_upgrade*]
#  Upgrades all puppet managed packages to latest.
#  Defaults to false
#
class tripleo::packages (
  $enable_install = false,
  $enable_upgrade = false,
) {

  # required for stages
  include ::stdlib

  if !str2bool($enable_install) and !str2bool($enable_upgrade) {
    case $::osfamily {
      'RedHat': {
        Package <| |> { provider => 'norpm' }
      }
      default: {
        warning('enable_install option not supported for this distro.')
      }
    }
  }

  if str2bool($enable_upgrade) {
    Package <| |> { ensure => 'latest' }
    # Running the package upgrade before managing Services in the main stage.
    # So we're sure that services will be able to restart with the new version
    # of the package.
    ensure_resource('class', 'tripleo::packages::upgrades', {
      'stage' => 'setup',
    })
  }

}
