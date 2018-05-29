# Copyright 2017 Red Hat, Inc.
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

# == Class: tripleo::stunnel
#
# Installs and starts stunnel
#
# [*manage_service*]
#   (Optional) Whether we'll be managing the stunnel service or not.
#   Defaults to true
#
# [*service_ensure*]
#   (Optional) Ensure the service be running or stopped
#   Defaults to 'running'
#
# [*foreground*]
#   (Optional) Sets the configuration for stunnel to run the process in
#   the foreground. This is useful when trying to run stunnel in a
#   container.
#   Defaults to 'no'
#
# [*debug*]
#   (Optional) Sets the debug level in stunnel.conf
#   Defaults to '4' which translates to 'warning'.
#
class tripleo::stunnel (
  $manage_service = true,
  $service_ensure = 'running',
  $foreground     = 'no',
  $debug          = 'warning',
){
  package { 'stunnel':
    ensure => 'present'
  }

  concat { '/etc/stunnel/stunnel.conf':
    ensure => present,
  }
  concat::fragment { 'stunnel-foreground':
    target  => '/etc/stunnel/stunnel.conf',
    order   => '10-foreground-config',
    content => template('tripleo/stunnel/foreground.erb'),
  }
  if $manage_service {
    Concat['/etc/stunnel/stunnel.conf'] ~> Service['stunnel']

    include ::tripleo::stunnel::systemd_unit

    service { 'stunnel':
      ensure => $service_ensure
    }
  }
}
