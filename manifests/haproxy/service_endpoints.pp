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
# == Define: tripleo::haproxy::service_endpoints
#
# Define used to create haproxyendpoints for composable services.
#
# === Parameters:
#
# [*service_name*]
#  (optional) The service_name to create the service endpoint(s) for.
#  Defaults to $title
#
define tripleo::haproxy::service_endpoints ($service_name = $title) {

  $underscore_name = regsubst($service_name, '-', '_', 'G')

  # This allows each composable service to load its own custom rules by
  # creating its own flat hiera key named:
  #   tripleo.<service name with underscores>.haproxy_endpoints
  #   tripleo.<service name with underscores>.haproxy_userlists
  $dots_endpoints = hiera("tripleo.${underscore_name}.haproxy_endpoints", {})
  $dots_userlists = hiera("tripleo.${underscore_name}.haproxy_userlists", {})

  # Supports standard "::" notation
  #   tripleo::<service name with underscores>::haproxy_endpoints
  #   tripleo::<service name with underscores>::haproxy_userlists
  $colons_endpoints = hiera("tripleo::${underscore_name}::haproxy_endpoints", {})
  $colons_userlists = hiera("tripleo::${underscore_name}::haproxy_userlists", {})

  # Merge hashes
  $service_endpoints = merge($colons_endpoints, $dots_endpoints)
  $service_userlists = merge($colons_userlists, $dots_userlists)

  create_resources('tripleo::haproxy::userlist', $service_userlists)
  create_resources('tripleo::haproxy::endpoint', $service_endpoints)
}
