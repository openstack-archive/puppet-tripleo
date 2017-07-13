# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::iscsid
#
# Nova Compute profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::iscsid (
  $step               = Integer(hiera('step')),
) {

  if $step >= 2 {
    # When utilising images for deployment, we need to reset the iSCSI initiator name to make it unique
    # https://bugzilla.redhat.com/show_bug.cgi?id=1244328
    ensure_resource('package', 'iscsi-initiator-utils', { ensure => 'present' })
    exec { 'reset-iscsi-initiator-name':
      command => '/bin/echo InitiatorName=$(/usr/sbin/iscsi-iname) > /etc/iscsi/initiatorname.iscsi',
      onlyif  => '/usr/bin/test ! -f /etc/iscsi/.initiator_reset',
      before  => File['/etc/iscsi/.initiator_reset'],
      require => Package['iscsi-initiator-utils'],
      tag     => 'iscsid_config'
    }
    file { '/etc/iscsi/.initiator_reset':
      ensure => present,
    }
  }
}
