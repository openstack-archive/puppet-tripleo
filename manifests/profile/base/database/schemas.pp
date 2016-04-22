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
# == Class: tripleo::profile::base::database::schemas
#
# OpenStack Database Schema profile for tripleo
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
# [*enable_aodh*]
#   (Optional) Whether to create schemas for Aodh
#   Defaults to true
#
# [*enable_ceilometer*]
#   (Optional) Whether to create schemas for Ceilometer
#   Defaults to true
#
# [*enable_cinder*]
#   (Optional) Whether to create schemas for Cinder
#   Defaults to true
#
# [*enable_heat*]
#   (Optional) Whether to create schemas for Heat
#   Defaults to true
#
# [*enable_keystone*]
#   (Optional) Whether to create schemas for Keystone
#   Defaults to true
#
# [*enable_glance*]
#   (Optional) Whether to create schemas for Glance
#   Defaults to true
#
# [*enable_gnocchi*]
#   (Optional) Whether to create schemas for Gnocchi
#   Defaults to true
#
# [*enable_nova*]
#   (Optional) Whether to create schemas for Nova
#   Defaults to true
#
# [*enable_neutron*]
#   (Optional) Whether to create schemas for Neutron
#   Defaults to true
#
# [*enable_sahara*]
#   (Optional) Whether to create schemas for Sahara
#   Defaults to true
#
# [*gnocchi_indexer_backend*]
#   (Optional) Type of backend used as Gnocchi indexer
#   Defaults to hiera('gnocchi_indexer_backend')
#
class tripleo::profile::base::database::schemas (
  $step                    = hiera('step'),
  $ceilometer_backend      = hiera('ceilometer_backend'),
  $enable_aodh             = true,
  $enable_ceilometer       = true,
  $enable_cinder           = true,
  $enable_heat             = true,
  $enable_keystone         = true,
  $enable_glance           = true,
  $enable_gnocchi          = true,
  $enable_nova             = true,
  $enable_neutron          = true,
  $enable_sahara           = true,
  $gnocchi_indexer_backend = hiera('gnocchi_indexer_backend'),
) {
  if $step >= 2 {
    if downcase($ceilometer_backend) == 'mysql' {
      if $enable_ceilometer {
        include ::ceilometer::db::mysql
      }
      if $enable_aodh {
        include ::aodh::db::mysql
      }
    }

    if $enable_gnocchi and downcase($gnocchi_indexer_backend) == 'mysql' {
      include ::gnocchi::db::mysql
    }

    if $enable_cinder {
      include ::cinder::db::mysql
    }

    if $enable_keystone {
      include ::keystone::db::mysql
    }

    if $enable_glance {
      include ::glance::db::mysql
    }

    if $enable_nova {
      include ::nova::db::mysql
      include ::nova::db::mysql_api
    }

    if $enable_neutron {
      include ::neutron::db::mysql
    }

    if $enable_heat {
      include ::heat::db::mysql
    }

    if $enable_sahara {
      include ::sahara::db::mysql
    }
  }
}
