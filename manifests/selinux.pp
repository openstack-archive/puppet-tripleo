#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
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
# == Class: tripleo::selinux
#
# Helper class to configure SELinux on nodes
#
# === Parameters:
#
# [*mode*]
#   (optional) SELinux mode the system should be in
#   Defaults to 'enforcing'
#   Possible values : disabled, permissive, enforcing
#
# [*directory*]
#   (optional) Path where to find the SELinux modules
#   Defaults to '/usr/share/selinux'
#
# [*booleans*]
#   (optional) Set of booleans to persistently enables
#   SELinux booleans are the one getsebool -a returns
#   Defaults []
#   Example: ['rsync_full_access', 'haproxy_connect_any']
#
# [*modules*]
#   (optional) Set of modules to load on the system
#   Defaults []
#   Example: ['module1', 'module2']
#   Note: Those module should be in the $directory path
#
class tripleo::selinux (
  $mode      = 'enforcing',
  $directory = '/usr/share/selinux/',
  $booleans  = [],
  $modules   = [],
) {

  if $::osfamily != 'RedHat'  {
    fail("OS family unsuppored yet (${::osfamily}), SELinux support is only limited to RedHat family OS")
  }

  Selboolean {
    persistent => true,
    value      => 'on',
  }

  Selmodule {
    ensure       => present,
    selmoduledir => $directory,
  }

  file { '/etc/selinux/config':
    ensure  => present,
    mode    => '0444',
    content => template('tripleo/selinux/sysconfig_selinux.erb')
  }

  $current_mode = $::selinux? {
    false   => 'disabled',
    default => $::selinux_current_mode,
  }

  if $current_mode != $mode {
    case $mode {
      /^(disabled|permissive)$/: {
        if $current_mode == 'enforcing' {
          exec { '/sbin/setenforce 0': }
        }
      }
      'enforcing': {
        exec { '/sbin/setenforce 1': }
      }
      default: {
        fail('You must specify a mode (enforcing, permissive, or disabled)')
      }
    }
  }

  selboolean { $booleans :
    persistent => true,
  }
  selmodule { $modules: }

}
