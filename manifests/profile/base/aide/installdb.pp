#########################################################################
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
# == Class: tripleo::profile::base::aide::installdb
#
# Aide profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::aide::installdb (
  $step = Integer(hiera('step')),
  ) {

  include ::tripleo::profile::base::aide

  exec { 'aide init':
    path        =>  '/usr/sbin/',
    command     => "aide --init --config ${::tripleo::profile::base::aide::aide_conf_path}",
    user        => 'root',
    refreshonly => true,
    subscribe   => Concat['aide.conf']
  }

  exec { 'install aide db':
    path        =>  '/bin/',
    command     => "cp -f ${::tripleo::profile::base::aide::aide_db_temp_path} ${::tripleo::profile::base::aide::aide_db_path}",
    user        => 'root',
    refreshonly => true,
    subscribe   => Exec['aide init']
  }

  file { $::tripleo::profile::base::aide::aide_db_path:
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0600',
    require => Exec['install aide db']
  }
}
