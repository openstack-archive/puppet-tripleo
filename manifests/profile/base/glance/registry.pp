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
# == Class: tripleo::profile::base::glance::registry
#
# Glance Registry profile for tripleo
#
# === Parameters
#
# [*sync_db*]
#   (Optional) Whether to run db sync
#   Defaults to undef
#
# [*manage_service*]
#   (Optional) Whether to manage the glance service
#   Defaults to undef
#
# [*enabled*]
#   (Optional) Whether to enable the glance service
#   Defaults to undef
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*glance_backend*]
#   (Optional) Glance backend(s) to use.
#   Defaults to downcase(hiera('glance_backend', 'swift'))
#
class tripleo::profile::base::glance::registry (
  $sync_db        = undef,
  $manage_service = undef,
  $enabled        = undef,
  $step           = hiera('step'),
  $glance_backend = downcase(hiera('glance_backend', 'swift')),
) {

  if $step >= 4 {
    # TODO: notifications, scrubber, etc.
    include ::glance
    include ::glance::config
    class { '::glance::registry' :
      sync_db        => $sync_db,
      manage_service => $manage_service,
      enabled        => $enabled,
    }
    include ::glance::notify::rabbitmq
    include join(['::glance::backend::', $glance_backend])
  }

}

