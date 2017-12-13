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
# == Define: tripleo::firewall::service_rules
#
# Define used to create firewall rules for composable services.
#
# === Parameters:
#
# [*service_name*]
#  (optional) The service_name to load firewall rules for.
#  Defaults to $title
#
define tripleo::firewall::service_rules ($service_name = $title) {

  $underscore_name = regsubst($service_name, '-', '_')

  # This allows each composable service to load its own custom rules by
  # creating its own flat hiera key named:
  #   tripleo.<service name with underscores>.firewall_rules
  $dots_rules = hiera("tripleo.${underscore_name}.firewall_rules", {})

  # Supports standard "::" notation:
  #   tripleo::<service name with underscores>::firewall_rules
  $colons_rules = hiera("tripleo::${underscore_name}::firewall_rules", {})

  # merge rules
  $firewall_rules = merge($colons_rules, $dots_rules)

  create_resources('tripleo::firewall::rule', $firewall_rules)
}
