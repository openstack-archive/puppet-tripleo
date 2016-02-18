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

  if !$enable_install and !$enable_upgrade {
    case $::osfamily {
      'RedHat': {
        Package <| |> { provider => 'norpm' }
      }
      default: {
        warning('enable_install option not supported for this distro.')
      }
    }
  }

  if $enable_upgrade {
    Package <| |> { ensure => 'latest' }

    case $::osfamily {
      'RedHat': {
        $pkg_upgrade_cmd = 'yum -y update'
      }
      default: {
        warning('Please specify a package upgrade command for distribution.')
      }
    }

    exec { 'package-upgrade':
      command => $pkg_upgrade_cmd,
      path    => '/usr/bin',
      timeout => 0,
    }
    # A resource chain to ensure the upgrade ordering we want:
    # 1) Upgrade all packages via exec.
    #    Note: The Package Puppet resources can be managed after or before package-upgrade,
    #          it does not matter. what we need to make sure is that they'll notify their
    #          respective services (if they have ~> in their manifests or here with the ->)
    #          for the other packages, they'll be upgraded before any Service notify.
    #          This approach prevents from Puppet dependencies cycle.
    # 2) This upgrade will be run before any Service notified & managed by Puppet.
    #    Note: For example, during the Puppet catalog, configuration will change for most of
    #          the services so the Services will be likely restarted after the package upgrade.
    Exec['package-upgrade'] -> Service <| |>

  }

}
