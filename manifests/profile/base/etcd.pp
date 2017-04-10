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
# == Class: tripleo::profile::base::etcd
#
# etcd profile for tripleo
#
# === Parameters
#
# [*bind_ip*]
#   (optional) IP to bind etcd service to.
#   Defaults to '127.0.0.1'.
#
# [*client_port*]
#   (optional) etcd client listening port.
#   Defaults to '2379'.
#
# [*peer_port*]
#   (optional) etcd peer listening port.
#   Defaults to '2380'.
#
# [*nodes*]
#   (Optional) Array of host(s) for etcd nodes.
#   Defaults to hiera('etcd_node_ips', []).
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::etcd (
  $bind_ip     = '127.0.0.1',
  $client_port = '2379',
  $peer_port   = '2380',
  $nodes       = hiera('etcd_node_names', []),
  $step        = hiera('step'),
) {
  if $step >= 2 {
    class {'::etcd':
      listen_client_urls          => "http://${bind_ip}:${client_port}",
      advertise_client_urls       => "http://${bind_ip}:${client_port}",
      listen_peer_urls            => "http://${bind_ip}:${peer_port}",
      initial_advertise_peer_urls => "http://${bind_ip}:${peer_port}",
      initial_cluster             => regsubst($nodes, '.+', "\\0=http://\\0:${peer_port}"),
      proxy                       => 'off',
    }
  }
}
