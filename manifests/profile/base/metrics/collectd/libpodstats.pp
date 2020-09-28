# Copyright 2018 Red Hat, Inc.
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
# == Define: tripleo::profile::base::metrics::collectd::sensubility
#
# This is used to create configuration file for collectd-sensubility plugin
#
# === Parameters
#
# [*ensure*]
#   (Optional) String. Action to perform with sensubility plugin
#   configuration file.
#   Defaults to 'present'
#
# [*config_path*]
#  (Optional) String. Path to configuration file.
#  Defaults to /etc/collectd.d/libpodstats.conf
class tripleo::profile::base::metrics::collectd::libpodstats (
    $ensure      = 'present',
    $config_path = '/etc/collectd.d/libpodstats.conf'
) {

  $db = '/usr/share/collectd/types.db.libpodstats'

  package { 'collectd-libpod-stats':
      ensure => $ensure
  }

  ::collectd::type { 'pod_cpu':
    target => $db,
    types  => [{
          ds_type => 'GAUGE',
          min     => 0,
          max     => 100.1,
          ds_name => 'percent',
      },
      {
          ds_type => 'DERIVE',
          min     => 0,
          max     => 'U',
          ds_name => 'time',
      }
    ]
  }

  ::collectd::type { 'pod_memory':
      target  => $db,
      ds_type => 'GAUGE',
      min     => 0,
      max     => 281474976710656,
      ds_name => 'value',
  }

  file { $config_path:
      ensure  => $ensure,
      mode    => '0644',
      content => template('tripleo/metrics/libpodstats.conf.epp'),
  }
}
