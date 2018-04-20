# Copyright 2017 Red Hat, Inc.
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

# == Class: tripleo::stunnel::service_proxy
#
# Configures a TLS proxy for a service.
#
# === Parameters
#
# [*accept_host*]
#   Host or IP where the tunnel will be accepting connections.
#
# [*accept_port*]
#   Port where the tunnel will be accepting connections.
#
# [*connect_port*]
#   Port where the tunnel will be proxying to.
#
# [*certificate*]
#   Cert that the TLS proxy will be using for the TLS connection.
#
# [*key*]
#   Key that the TLS proxy will be using for the TLS connection.
#
# [*client*]
#   Whether this proxy is meant for client connections.
#   Defaults to 'no'
#
# [*connect_host*]
#   Host where the tunnel will be proxying to.
#   Defaults to 'localhost'
#
# [*ssl_version*]
#   (Optional) select the TLS protocol version
#   Defaults to 'TLSv1.2'
#
define tripleo::stunnel::service_proxy (
  $accept_host,
  $accept_port,
  $connect_port,
  $certificate,
  $key,
  $client = 'no',
  $connect_host = 'localhost',
  $ssl_version = 'TLSv1.2'
) {
  concat::fragment { "stunnel-service-${name}":
    target  => '/etc/stunnel/stunnel.conf',
    order   => "20-${name}",
    content => template('tripleo/stunnel/service.erb'),
  }

  Concat::Fragment["stunnel-service-${name}"] ~> Service<| title == 'stunnel' |>
}
