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
# == Class: tripleo::profile::base::ironic
#
# Ironic profile for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*sync_db*]
#   (Optional) Whether to run db sync
#   Defaults to true
#
class tripleo::profile::base::ironic (
  $step    = hiera('step'),
  $sync_db = true,
) {

  if $step >= 3 {
    include ::ironic

    # Database is accessed by both API and conductor, hence it's here.
    if $sync_db {
      include ::ironic::db::mysql
      include ::ironic::db::sync
    }
  }
}
