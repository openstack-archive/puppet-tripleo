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
#
# == Class: tripleo::profile::base::rsyslog::sidecar
#
# Configure the rsyslog sidecar container configuration.
#
# === Parameters
#
# [*socket_path*]
#   (Optional) Path to the socket that rsyslog with read from.
#   Defaults to '/sockets/log'
#
class tripleo::profile::base::rsyslog::sidecar (
  $socket_path = '/sockets/log'
) {
  file { '/etc/rsyslog.conf':
    ensure  => file,
    content => template('tripleo/rsyslog_sidecar/rsyslog.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
  }
}
