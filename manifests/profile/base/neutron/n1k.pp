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
# == Class: tripleo::profile::base::neutron::n1k
#
# Neutron N1k Mechanism Driver profile for tripleo
#
# === Parameters
#
# [*n1kv_source*]
#   (Optional) The source location for the N1Kv
#   Defaults to hiera('n1kv_vem_source', undef)
#
# [*n1kv_version*]
#   (Optional) The version of N1Kv to use
#   Defaults to hiera('n1kv_vem_version', undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::n1k (
  $n1kv_source  = hiera('n1kv_vem_source', undef),
  $n1kv_version = hiera('n1kv_vem_version', undef),
  $step         = Integer(hiera('step')),
) {
  include ::neutron::plugins::ml2::cisco::nexus1000v
  include ::tripleo::profile::base::neutron

  if $step >= 4 {
    class { '::neutron::agents::n1kv_vem':
      n1kv_source  => $n1kv_source,
      n1kv_version => $n1kv_version,
    }

    class { '::n1k_vsm':
      n1kv_source       => $n1kv_source,
      n1kv_version      => $n1kv_version,
      pacemaker_control => false,
    }
  }
}
