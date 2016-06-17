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
# == Class: tripleo::profile::base::nova::compute
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
class tripleo::profile::base::nova::compute (
  $step = hiera('step'),
) {

  if $step >= 4 {
    # deploy basic bits for nova
    include ::tripleo::profile::base::nova

    # deploy basic bits for nova-compute
    include ::nova::compute

    # deploy bits to connect nova compute to neutron
    include ::nova::network::neutron

    # When utilising images for deployment, we need to reset the iSCSI initiator name to make it unique
    # https://bugzilla.redhat.com/show_bug.cgi?id=1244328
    exec { 'reset-iscsi-initiator-name':
      command => '/bin/echo InitiatorName=$(/usr/sbin/iscsi-iname) > /etc/iscsi/initiatorname.iscsi',
      onlyif  => '/usr/bin/test ! -f /etc/iscsi/.initiator_reset',
      before  => File['/etc/iscsi/.initiator_reset'],
    }
    file { '/etc/iscsi/.initiator_reset':
      ensure => present,
    }
  }

}
