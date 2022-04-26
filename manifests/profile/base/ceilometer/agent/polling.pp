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
# == Class: tripleo::profile::base::ceilometer::agent::polling
#
# Ceilometer polling Agent profile for tripleo
#
# === Parameters
#
# [*central_namespace*]
#   (Optional) Use central namespace for polling agent.
#   Defaults to lookup('central_namespace', undef, undef, false)
#
# [*compute_namespace*]
#   (Optional) Use compute namespace for polling agent.
#   Defaults to lookup('compute_namespace', undef, undef, false)
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to lookup('enable_internal_tls', undef, undef, false)
#
# [*ipmi_namespace*]
#   (Optional) Use ipmi namespace for polling agent.
#   Defaults to lookup('ipmi_namespace', undef, undef, false)
#
# [*ceilometer_redis_password*]
#   (Optional) redis password to configure coordination url
#   Defaults to lookup('ceilometer_redis_password')
#
# [*redis_vip*]
#   (Optional) redis vip to configure coordination url
#   Defaults to lookup('redis_vip')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::ceilometer::agent::polling (
  $central_namespace         = lookup('central_namespace', undef, undef, false),
  $compute_namespace         = lookup('compute_namespace', undef, undef, false),
  $enable_internal_tls       = lookup('enable_internal_tls', undef, undef, false),
  $ipmi_namespace            = lookup('ipmi_namespace', undef, undef, false),
  $ceilometer_redis_password = lookup('ceilometer_redis_password'),
  $redis_vip                 = lookup('redis_vip'),
  $step                      = Integer(lookup('step')),
) {
  include tripleo::profile::base::ceilometer

  if $enable_internal_tls {
    $tls_query_param = '?ssl=true'
  } else {
    $tls_query_param = ''
  }

  if $step >= 4 {
    include ceilometer::agent::service_credentials
    class { 'ceilometer::coordination':
      backend_url  => join(['redis://:', $ceilometer_redis_password, '@', normalize_ip_for_uri($redis_vip), ':6379/', $tls_query_param]),
    }
    class { 'ceilometer::agent::polling':
      central_namespace => $central_namespace,
      compute_namespace => $compute_namespace,
      ipmi_namespace    => $ipmi_namespace,
    }
  }
}
