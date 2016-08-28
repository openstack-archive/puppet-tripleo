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
# == Class: tripleo::profile::base::glance::api
#
# Glance API profile for tripleo
#
# === Parameters
#
# [*glance_backend*]
#   (Optional) Glance backend(s) to use.
#   Defaults to downcase(hiera('glance_backend', 'swift'))
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')

class tripleo::profile::base::glance::api (
  $glance_backend = downcase(hiera('glance_backend', 'swift')),
  $step           = hiera('step'),
  $rabbit_hosts   = hiera('rabbitmq_node_ips', undef),
) {

  if $step >= 4 {
    case $glance_backend {
        'swift': { $backend_store = 'glance.store.swift.Store' }
        'file': { $backend_store = 'glance.store.filesystem.Store' }
        'rbd': { $backend_store = 'glance.store.rbd.Store' }
        default: { fail('Unrecognized glance_backend parameter.') }
    }
    $http_store = ['glance.store.http.Store']
    $glance_store = concat($http_store, $backend_store)

    # TODO: notifications, scrubber, etc.
    include ::glance
    include ::glance::config
    class { '::glance::api':
      stores => $glance_store,
    }
    class { '::glance::notify::rabbitmq' :
      rabbit_hosts => $rabbit_hosts,
    }
    include join(['::glance::backend::', $glance_backend])
  }

}
