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
# == Class: tripleo::profile::base::haproxy
#
# Loadbalancer profile for tripleo
#
# === Parameters
#
# [*certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Example with hiera:
#     tripleo::profile::base::haproxy::certificates_specs:
#       undercloud-haproxy-public-cert:
#         service_pem: <haproxy ready pem file>
#         service_certificate: <service certificate path>
#         service_key: <service key path>
#         hostname: <undercloud fqdn>
#         postsave_cmd: <command to update certificate on resubmit>
#         principal: "haproxy/<undercloud fqdn>"
#   Defaults to {}.
#
# [*enable_load_balancer*]
#   (Optional) Whether or not loadbalancer is enabled.
#   Defaults to hiera('enable_load_balancer', true).
#
# [*manage_firewall*]
#  (optional) Enable or disable firewall settings for ports exposed by HAProxy
#  (false means disabled, and true means enabled)
#  Defaults to hiera('tripleo::firewall::manage_firewall', true)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::haproxy (
  $certificates_specs            = {},
  $enable_load_balancer          = hiera('enable_load_balancer', true),
  $manage_firewall               = hiera('tripleo::firewall::manage_firewall', true),
  $step                          = Integer(hiera('step')),
) {
  if $step >= 1 {
    if $enable_load_balancer {
      class {'::tripleo::haproxy':
        internal_certificates_specs => $certificates_specs,
        manage_firewall             => $manage_firewall,
      }

      unless hiera('tripleo::haproxy::haproxy_service_manage', true) {
        # Reload HAProxy configuration if the haproxy class has refreshed or any
        # HAProxy frontend endpoint has changed.
        exec { 'haproxy-reload':
          command     => 'systemctl reload haproxy',
          path        => ['/usr/bin', '/usr/sbin'],
          refreshonly => true,
          onlyif      => 'systemctl is-active haproxy | grep -q active',
          subscribe   => Class['::haproxy']
        }
        Haproxy::Listen<||> ~> Exec['haproxy-reload']
        Haproxy::Balancermember<||> ~> Exec['haproxy-reload']
      }
    }
  }

}

