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
# == Class: tripleo::profile::base::keepalived
#
# Loadbalancer profile for tripleo
#
# === Parameters
#
# [*enable_load_balancer*]
#   (Optional) Whether or not loadbalancer is enabled.
#   Defaults to hiera('enable_load_balancer', true).
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*control_virtual_interface*]
#   (Optional) Interface specified for control plane network
#   Defaults to hiera('tripleo::keepalived::control_virtual_interface', false)
#
# [*control_virtual_ip*]
#   Virtual IP address used for control plane network
#   Defaults to hiera('tripleo::keepalived::controller_virtual_ip')
#
# [*public_virtual_interface*]
#   (Optional) Interface specified for public/external network
#   Defaults to hiera('tripleo::keepalived::public_virtual_interface', false)
#
# [*public_virtual_ip*]
#   Virtual IP address used for public/ network
#   Defaults to hiera('tripleo::keepalived::public_virtual_ip')
#
class tripleo::profile::base::keepalived (
  $enable_load_balancer      = hiera('enable_load_balancer', true),
  $control_virtual_interface = hiera('tripleo::keepalived::control_virtual_interface', false),
  $control_virtual_ip        = hiera('tripleo::keepalived::controller_virtual_ip'),
  $public_virtual_interface  = hiera('tripleo::keepalived::public_virtual_interface', false),
  $public_virtual_ip         = hiera('tripleo::keepalived::public_virtual_ip'),
  $step                      = Integer(hiera('step')),
) {
  if $step >= 1 {
    if $enable_load_balancer and hiera('enable_keepalived', true){
      if ! $control_virtual_interface {
        $control_detected_interface = interface_for_ip($control_virtual_ip)
        if ! $control_detected_interface {
          fail('Unable to find interface for control plane network')
        }
      } else {
        $control_detected_interface = $control_virtual_interface
      }

      if ! $public_virtual_interface {
        $public_detected_interface = interface_for_ip($public_virtual_ip)
        if ! $public_detected_interface {
          fail('Unable to find interface for public network')
        }
      } else {
        $public_detected_interface = $public_virtual_interface
      }

      class { '::tripleo::keepalived':
        control_virtual_interface => $control_detected_interface,
        public_virtual_interface  => $public_detected_interface,
      }
    }
  }
}

