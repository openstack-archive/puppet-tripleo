#########################################################################
# Copyright (C) 2017 Red Hat Inc.
#
# Author: Luke Hinds  <lhinds@redhat.com>
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
# == Class: tripleo::profile::base::aide
#
# Aide profile for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*aide_conf_path*]
#   The aide configuration file to use for rules and db path
#   Defaults to hiera('aide_conf_path', '/etc/aide.conf')
#
# [*aide_db_path*]
#   (Optional) The location of AIDE's integrity database file
#   Defaults to hiera('aide_db_path', '/var/lib/aide/aide.db')
#
# [*aide_db_temp_path*]
#   (Optional) The staging location during integrity database creation
#   Defaults to hiera('aide_db_temp_path', '/var/lib/aide/aide.db.new')
#
# [*aide_rules*]
#   A hiera based hash of aides integrity rules
#   Defaults to  hiera('rules', {})
#
class tripleo::profile::base::aide (
  $step              = Integer(hiera('step')),
  $aide_conf_path    = hiera('aide_conf_path', '/etc/aide.conf'),
  $aide_db_path      = hiera('aide_db_path', '/var/lib/aide/aide.db'),
  $aide_db_temp_path = hiera('aide_db_temp_path', '/var/lib/aide/aide.db.new'),
  $aide_rules        = hiera('aide_rules', {})
) {

  if $step >=5 {
    package { 'aide':
      ensure => 'present'
    }

    contain ::tripleo::profile::base::aide::installdb

    concat { 'aide.conf':
      path           => $aide_conf_path,
      owner          => 'root',
      group          => 'root',
      mode           => '0600',
      ensure_newline => true,
      require        => Package['aide']
    }

    concat::fragment { 'aide.conf.header':
      target  => 'aide.conf',
      order   => 0,
      content => template( 'tripleo/aide/aide.conf.erb')
    }

    create_resources('tripleo::profile::base::aide::rules', $aide_rules)

    contain ::tripleo::profile::base::aide::cron
  }
}
