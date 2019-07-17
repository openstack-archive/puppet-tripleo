# Copyright 2019 Red Hat, Inc.
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
# == Define: tripleo::profile::base::metrics::collectd::sqlalchemy_collectd
#
# This is used to create configuration file for sqlalchemy-collectd plugin
#
# === Parameters
#
# [*bind_host*]
#   (Optional) String. Hostname to listen on.  Defaults to 0.0.0.0
#
# [*bind_port*]
#   (Optional) Integer.  Port to listen on.  defaults to 25827.
#
# [*log_messages*]
#   (Optional) String. Log level for the plugin, set to "debug" to show
#   messages received.
#   Defaults to 'info'
#
#
define tripleo::profile::base::metrics::collectd::sqlalchemy_collectd (
  $bind_host      = '0.0.0.0',
  $bind_port      = 25827,
  $log_messages   = 'info',

) {
  include ::collectd

  package { 'python-collectd-sqlalchemy':
    ensure => 'present',
  }

  ::collectd::plugin::python::module { 'collectd_sqlalchemy':
      config        => [{
          'listen'   => [$bind_host, $bind_port],
          'loglevel' => $log_messages
      }],
      module_import => 'sqlalchemy_collectd.server.plugin',
  }

}
