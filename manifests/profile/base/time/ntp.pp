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
# == Class: tripleo::profile::base::ntp
#
# Enable NTP via composable services.
#

class tripleo::profile::base::time::ntp {
  # If installed, we don't want chrony to conflict with ntp. LP#1665426
  # It should be noted that this work even if the package is not installed
  service { 'chronyd':
    ensure => stopped,
    enable => false,
    before => Class['ntp']
  }
  include ::ntp
}
