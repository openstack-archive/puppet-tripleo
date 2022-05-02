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
# == Class: tripleo::profile::base::gnocchi
#
# Gnocchi profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('gnocchi_api_short_bootstrap_node_name')
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*gnocchi_redis_password*]
#  (Required) Password for the gnocchi redis user for the coordination url
#  Defaults to hiera('gnocchi_redis_password')
#
# [*redis_vip*]
#  (Required) Redis ip address for the coordination url
#  Defaults to hiera('redis_vip')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::gnocchi (
  $bootstrap_node         = hiera('gnocchi_api_short_bootstrap_node_name', undef),
  $enable_internal_tls    = hiera('enable_internal_tls', false),
  $gnocchi_redis_password = hiera('gnocchi_redis_password'),
  $redis_vip              = hiera('redis_vip'),
  $step                   = Integer(hiera('step')),
) {

  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if $enable_internal_tls {
    $tls_query_param = '?ssl=true'
  } else {
    $tls_query_param = ''
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {

    class { 'gnocchi':
      coordination_url => join(['redis://:', $gnocchi_redis_password, '@', normalize_ip_for_uri($redis_vip), ':6379/', $tls_query_param]),
    }
    include gnocchi::config
    include gnocchi::cors
    include gnocchi::db
    include gnocchi::logging
  }
}
