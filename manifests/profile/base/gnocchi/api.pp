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
# == Class: tripleo::profile::base::gnocchi::api
#
# Gnocchi profile for tripleo api
#
# === Parameters
#
# [*gnocchi_backend*]
#   (Optional) Gnocchi backend string file, swift or rbd
#   Defaults to swift
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*sync_db*]
#   (Optional) Whether to run db sync
#   Defaults to undef

class tripleo::profile::base::gnocchi::api (
  $gnocchi_backend = downcase(hiera('gnocchi_backend', 'swift')),
  $step            = hiera('step'),
  $sync_db         = true,
) {

  include ::tripleo::profile::base::gnocchi

  if $step >= 3 and $sync_db {
    include ::gnocchi::db::mysql
    include ::gnocchi::db::sync
  }

  if $step >= 4 {
    include ::gnocchi::api
    include ::gnocchi::wsgi::apache
    include ::gnocchi::storage
    case $gnocchi_backend {
      'swift': { include ::gnocchi::storage::swift }
      'file': { include ::gnocchi::storage::file }
      'rbd': { include ::gnocchi::storage::ceph }
      default: { fail('Unrecognized gnocchi_backend parameter.') }
    }
  }
}
