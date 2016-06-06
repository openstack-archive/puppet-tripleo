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
# == Class: tripleo::profile::pacemaker::nova::vncproxy
#
# Nova vncproxy with Pacemaker profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pacemaker_master*]
#   (Optional) The hostname of the pacemaker master
#   Defaults to hiera('bootstrap_nodeid')
#
class tripleo::profile::pacemaker::nova::vncproxy (
  $step             = hiera('step'),
  $pacemaker_master = hiera('bootstrap_nodeid'),
) {

  include ::nova::params
  include ::tripleo::profile::pacemaker::nova
  include ::tripleo::profile::base::nova::vncproxy

  if $step >= 5 and downcase($::hostname) == $pacemaker_master {
    pacemaker::resource::service { $::nova::params::vncproxy_service_name:
      clone_params => 'interleave=true',
    }
  }

}
