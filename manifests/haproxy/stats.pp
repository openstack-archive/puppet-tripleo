# Copyright 2014 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: tripleo::haproxy::stats
#
# Configure the HAProxy stats interface
#
# [*haproxy_listen_bind_param*]
#  A list of params to be added to the HAProxy listener bind directive.
#
# [*ip*]
#  IP Address on which the stats interface is listening on. This right now
#  assumes that it's in the ctlplane network.
#
# [*password*]
#  Password for haproxy stats authentication.  When set, authentication is
#  enabled on the haproxy stats endpoint.
#  A string.
#  Defaults to undef
#
# [*certificate*]
#  Filename of an HAProxy-compatible certificate and key file
#  When set, enables SSL on the haproxy stats endpoint using the specified file.
#  Defaults to undef
#
# [*user*]
#  Username for haproxy stats authentication.
#  A string.
#  Defaults to 'admin'
#
class tripleo::haproxy::stats (
  $haproxy_listen_bind_param,
  $ip,
  $password    = undef,
  $certificate = undef,
  $user        = 'admin'
) {
  if $certificate {
    $haproxy_stats_bind_opts = {
      "${ip}:1993" => union($haproxy_listen_bind_param, ['ssl', 'crt', $certificate]),
    }
  } else {
    $haproxy_stats_bind_opts = {
      "${ip}:1993" => $haproxy_listen_bind_param,
    }
  }

  $stats_base = ['enable', 'uri /']
  if $password {
    $stats_config = union($stats_base, ["auth ${user}:${password}"])
  } else {
    $stats_config = $stats_base
  }
  haproxy::listen { 'haproxy.stats':
    bind             => $haproxy_stats_bind_opts,
    mode             => 'http',
    options          => {
      'stats' => $stats_config,
    },
    collect_exported => false,
  }
}
