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
# Iscsid profile for tripleo
#
# === Parameters
#
# [*chap_algs*]
#   (Optional) Comma separated list of algorithms to use in CHAP protocol
#   Defaults to 'SHA3-256,SHA256,SHA1,MD5'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::iscsid (
  $chap_algs = 'SHA3-256,SHA256,SHA1,MD5',
  $step      = Integer(hiera('step')),
) {

  if $step >= 2 {
    # When utilising images for deployment, we need to reset the iSCSI initiator name to make it unique
    # https://bugzilla.redhat.com/show_bug.cgi?id=1244328
    ensure_resource('package', 'iscsi-initiator-utils', { ensure => 'present' })

    # THT supplies a volume mount to the host's /etc/iscsi directory (at
    # /tmp/iscsi.host). If the sentinel file (.initiator_reset) exists on the
    # host, then copy the IQN from the host. This ensures the IQN is reset
    # once, and only once.
    exec { 'sync-iqn-from-host':
      command => '/bin/cp /tmp/iscsi.host/.initiator_reset /tmp/iscsi.host/initiatorname.iscsi /etc/iscsi/',
      onlyif  => '/usr/bin/test -f /tmp/iscsi.host/.initiator_reset',
      before  => Exec['reset-iscsi-initiator-name'],
      tag     => 'iscsid_config'
    }

    exec { 'reset-iscsi-initiator-name':
      command => '/bin/echo InitiatorName=$(/usr/sbin/iscsi-iname) > /etc/iscsi/initiatorname.iscsi',
      onlyif  => '/usr/bin/test ! -f /etc/iscsi/.initiator_reset',
      before  => File['/etc/iscsi/.initiator_reset'],
      require => Package['iscsi-initiator-utils'],
      tag     => 'iscsid_config'
    }

    file { '/etc/iscsi/.initiator_reset':
      ensure => present,
      before => Exec['sync-iqn-to-host'],
    }

    exec { 'sync-iqn-to-host':
      command => '/bin/cp /etc/iscsi/initiatorname.iscsi /etc/iscsi/.initiator_reset /tmp/iscsi.host/',
      onlyif  => [
        '/usr/bin/test -d /tmp/iscsi.host',
        '/usr/bin/test ! -f /tmp/iscsi.host/iscsi/.initiator_reset',
        ],
      tag     => 'iscsid_config',
    }

    $chap_algs_real = join(any2array($chap_algs), ',')
    augeas {'chap_algs in /etc/iscsi/iscsid.conf':
      context => '/files/etc/iscsi/iscsid.conf',
      changes => ["set node.session.auth.chap_algs ${chap_algs_real}"],
    }
  }
}
