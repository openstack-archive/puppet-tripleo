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
# == Class: tripleo::profile::base::pacemaker::schemas
#
# OpenStack Database Schema Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current deployment step
#   Defaults to hiera('step')
#
# [*ceilometer_backend*]
#   (Optional) The backend used by ceilometer, usually either 'mysql'
#   or 'mongodb'
#   Defaults to hiera('ceilometer_backend')
#
# [*gnocchi_indexer_backend*]
#   (Optional) Type of backend used as Gnocchi indexer
#   Defaults to hiera('gnocchi_indexer_backend')
#
# [*pacemaker_master*]
#   (Optional) The hostname of the pacemaker master in this cluster
#   Defaults to hiera('bootstrap_nodeid')
#
class tripleo::profile::pacemaker::database::schemas (
  $step                    = hiera('step'),
  $ceilometer_backend      = hiera('ceilometer_backend'),
  $gnocchi_indexer_backend = hiera('gnocchi_indexer_backend'),
  $pacemaker_master        = hiera('bootstrap_nodeid')
) {
  if downcase($pacemaker_master) == $::hostname and $step >= 2 {
    include ::tripleo::profile::base::database::schemas

    if downcase($ceilometer_backend) == 'mysql' {
      Exec['galera-ready'] -> Class['::ceilometer::db::mysql']
      Exec['galera-ready'] -> Class['::aodh::db::mysql']
    }

    if downcase($gnocchi_indexer_backend) == 'mysql' {
      Exec['galera-ready'] -> Class['::gnocchi::db::mysql']
    }

    Exec['galera-ready'] -> Class['::cinder::db::mysql']
    Exec['galera-ready'] -> Class['::glance::db::mysql']
    Exec['galera-ready'] -> Class['::keystone::db::mysql']
    Exec['galera-ready'] -> Class['::nova::db::mysql']
    Exec['galera-ready'] -> Class['::nova::db::mysql_api']
    Exec['galera-ready'] -> Class['::neutron::db::mysql']
    Exec['galera-ready'] -> Class['::heat::db::mysql']
    Exec['galera-ready'] -> Class['::sahara::db::mysql']
  }
}
