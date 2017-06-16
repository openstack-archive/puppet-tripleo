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
# == Class: tripleo::profile::base::metrics::collectd
#
# Collectd configuration for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*collectd_server*]
#   (Optional) String. The name or address of a collectd server to
#   which we should send metrics.
#
# [*collectd_port*]
#   (Optional) Integer. The port to which we will connect on the
#   collectd server.
#
# [*collectd_username*]
#   (Optional) String.  Username for authenticating to the remote
#   collectd server.
#
# [*collectd_password*]
#   (Optional) String. Password for authenticating to the remote
#   collectd server.
#
# [*collectd_securitylevel*]
#   (Optional) String.
#
# [*service_names*]
#   (Optional) List of strings.  A list of active services in this tripleo
#   deployment. This is used to look up service-specific plugins that
#   need to be installed.
class tripleo::profile::base::metrics::collectd (
  $step = Integer(hiera('step')),

  $collectd_server = undef,
  $collectd_port = undef,
  $collectd_username = undef,
  $collectd_password = undef,
  $collectd_securitylevel = undef,
  $service_names = hiera('service_names', [])
) {
  if $step >= 3 {
    include ::collectd

    if ! ($collectd_securitylevel in [undef, 'None', 'Sign', 'Encrypt']) {
      fail('collectd_securitylevel must be one of (None, Sign, Encrypt).')
    }

    # Load per-service plugin configuration
    ::tripleo::profile::base::metrics::collectd::collectd_service {
      $service_names: }

    # Because THT doesn't allow us to default values to undef, we need
    # to perform a number of transformations here to avoid passing a bunch of
    # empty strings to the collectd plugins.

    $_collectd_username = empty($collectd_username) ? {
      true    => undef,
      default => $collectd_username
    }

    $_collectd_password = empty($collectd_password) ? {
      true    => undef,
      default => $collectd_password
    }

    $_collectd_port = empty($collectd_port) ? {
      true    => undef,
      default => $collectd_port
    }

    $_collectd_securitylevel = empty($collectd_securitylevel) ? {
      true    => undef,
      default => $collectd_securitylevel
    }

    if ! empty($collectd_server) {
      ::collectd::plugin::network::server { $collectd_server:
        username      => $_collectd_username,
        password      => $_collectd_password,
        port          => $_collectd_port,
        securitylevel => $_collectd_securitylevel,
      }
    }
  }
}
