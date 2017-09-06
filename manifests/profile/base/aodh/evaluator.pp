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
# == Class: tripleo::profile::base::aodh::evaluator
#
# aodh evaluator profile for tripleo
#
# === Parameters
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::aodh::evaluator (
  $enable_internal_tls = hiera('enable_internal_tls', false),
  $step                = Integer(hiera('step')),
) {

  include ::tripleo::profile::base::aodh
  if $enable_internal_tls {
    $tls_query_param = '?ssl=true'
  } else {
    $tls_query_param = ''
  }

  if $step >= 4 {
    class { '::aodh::evaluator':
      coordination_url => join(['redis://:', hiera('aodh_redis_password'), '@', normalize_ip_for_uri(hiera('redis_vip')), ':6379/', $tls_query_param]),
    }
  }

}

