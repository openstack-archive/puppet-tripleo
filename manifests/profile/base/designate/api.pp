# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::base::designate::api
#
# Designate API server profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*listen_ip*]
#   (Optional) The IP on which the API should listen.
#   Defaults to 0.0.0.0
#
# [*listen_port*]
#   (Optional) The port on which the API should listen.
#   Defaults to 9001
#
class tripleo::profile::base::designate::api (
  $step           = Integer(hiera('step')),
  $listen_ip      = '0.0.0.0',
  $listen_port    = '9001',
) {

  include ::tripleo::profile::base::designate

  if ($step >= 3) {
    $listen_uri = normalize_ip_for_uri($listen_ip)
    include ::designate::keystone::authtoken
    class { '::designate::api':
      listen => "${listen_uri}:${listen_port}",
    }
  }
}
