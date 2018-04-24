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

# == Class: tripleo::network::os_net_config
#
# Configure os-net-config for TripleO.
#
class tripleo::network::os_net_config {

  include ::vswitch::ovs
  ensure_packages('os-net-config', { ensure => present })

  exec { 'os-net-config':
    command => '/bin/os-net-config -c /etc/os-net-config/config.json -v --detailed-exit-codes',
    returns => [0, 2],
    require => [
      Package['os-net-config'],
      Package['openvswitch'],
      Service['openvswitch'],
    ],
    onlyif  => "/bin/grep -q '[^[:space:]]' /etc/os-net-config/config.json",
    notify  => Exec['trigger-keepalived-restart'],
  }

  # By modifying the keepalived.conf file we ensure that puppet will
  # trigger a restart of keepalived during the main stage. Adding back
  # any lost conf during the os-net-config step.
  exec { 'trigger-keepalived-restart':
    command     => '/usr/bin/echo "# Restart keepalived" >> /etc/keepalived/keepalived.conf',
    path        => '/usr/bin:/bin',
    refreshonly => true,
    # Only if keepalived is installed
    onlyif      => 'test -e /etc/keepalived/keepalived.conf',
  }
}
