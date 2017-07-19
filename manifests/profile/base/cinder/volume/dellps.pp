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
# == Class: tripleo::profile::base::cinder::volume::dellps
#
# Cinder Volume  for dellps profile tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) Name given to the Cinder backend stanza
#   Defaults to 'tripleo_dellps'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::dellps (
  $backend_name = hiera('cinder::backend::eqlx::volume_backend_name', 'tripleo_dellps'),
  $step         = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::eqlx { $backend_name :
      san_ip             => hiera('cinder::backend::eqlx::san_ip', undef),
      san_login          => hiera('cinder::backend::eqlx::san_login', undef),
      san_password       => hiera('cinder::backend::eqlx::san_password', undef),
      san_private_key    => hiera('cinder::backend::eqlx::san_private_key', undef),
      san_thin_provision => hiera('cinder::backend::eqlx::san_thin_provision', undef),
      eqlx_group_name    => hiera('cinder::backend::eqlx::eqlx_group_name', undef),
      eqlx_pool          => hiera('cinder::backend::eqlx::eqlx_pool', undef),
      use_chap_auth      => hiera('cinder::backend::eqlx::eqlx_use_chap', undef),
      chap_username      => hiera('cinder::backend::eqlx::eqlx_chap_login', undef),
      chap_password      => hiera('cinder::backend::eqlx::eqlx_chap_password', undef),
    }
  }

}
