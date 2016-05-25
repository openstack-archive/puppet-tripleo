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
# == Class: tripleo::profile::base::loadbalancer
#
# Loadbalancer profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*enable_load_balancer*]
#   (Optional) Whether or not loadbalancer is enabled.
#   Defaults to hiera('enable_load_balancer', true).
#
# [*controller_node_ips*]
#   (Optional) List of IPs for controller nodes.
#   Defaults to split(hiera('controller_node_ips'), ',')).
#
# [*controller_node_names*]
#   (Optional) List of hostnames for controller nodes.
#   Defaults to split(downcase(hiera('controller_node_names')), ',').
#
class tripleo::profile::base::loadbalancer (
  $enable_load_balancer   = hiera('enable_load_balancer', true),
  $controller_node_ips    = split(hiera('controller_node_ips'), ','),
  $controller_node_names  = split(downcase(hiera('controller_node_names')), ','),
  $step                   = hiera('step'),
) {

  if $step >= 1 {
    if $enable_load_balancer {
      # TODO(emilien): remove this conditional once
      # https://review.openstack.org/#/c/320411/ is merged.
      if hiera('tripleo::loadbalancer::keystone_admin', undef) {
        class { '::tripleo::loadbalancer':
          controller_hosts       => $controller_node_ips,
          controller_hosts_names => $controller_node_names,
        }
      } else {
        class { '::tripleo::haproxy':
          controller_hosts       => $controller_node_ips,
          controller_hosts_names => $controller_node_names,
        }
      }
    }
  }

}

