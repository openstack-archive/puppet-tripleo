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
# == Class: tripleo::profile::base::database::mysql
#
# MySQL profile for tripleo
#
# === Parameters
#
# [*manage_resources*]
#   (Optional) Whether or not manage root user, root my.cnf, and service.
#   Defaults to true
#
# [*mysql_server_options*]
#   (Optional) Extras options to deploy MySQL. Useful when deploying Galera cluster.
#   Should be an hash.
#   Defaults to {}
#
# [*remove_default_accounts*]
#   (Optional) Whether or not remove default MySQL accounts.
#   Defaults to true
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::database::mysql (
  $manage_resources        = true,
  $mysql_server_options    = {},
  $remove_default_accounts = true,
  $step                    = hiera('step'),

) {

  validate_hash($mysql_server_options)

  # non-ha scenario
  if $manage_resources {
    $mysql_step = 2
  } else {
  # ha scenario
    $mysql_step = 1
  }
  if $step >= $mysql_step {
    if str2bool(hiera('enable_galera', true)) {
      $mysql_config_file = '/etc/my.cnf.d/galera.cnf'
    } else {
      $mysql_config_file = '/etc/my.cnf.d/server.cnf'
    }
    # TODO Galara
    # FIXME: due to https://bugzilla.redhat.com/show_bug.cgi?id=1298671 we
    # set bind-address to a hostname instead of an ip address; to move Mysql
    # from internal_api on another network we'll have to customize both
    # MysqlNetwork and ControllerHostnameResolveNetwork in ServiceNetMap
    $mysql_server_default = {
      'mysqld' => {
        'bind-address'     => $::hostname,
        'max_connections'  => hiera('mysql_max_connections'),
        'open_files_limit' => '-1',
      }
    }
    $mysql_server_options_real = deep_merge($mysql_server_default, $mysql_server_options)
    class { '::mysql::server':
      config_file             => $mysql_config_file,
      override_options        => $mysql_server_options_real,
      create_root_user        => $manage_resources,
      create_root_my_cnf      => $manage_resources,
      service_manage          => $manage_resources,
      service_enabled         => $manage_resources,
      remove_default_accounts => $remove_default_accounts,
    }
  }

}
