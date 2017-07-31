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
# == Class: tripleo::profile::pacemaker::clustercheck
#
# Clustercheck, galera health check profile for tripleo
#
# === Parameters
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*bind_address*]
#   (Optional) The address that the local mysql instance should bind to.
#   Defaults to hiera('mysql_bind_host')
#
# [*clustercheck_user*]
#   (Optional) The name of the clustercheck user.
#   Defaults to 'clustercheck'
#
# [*clustercheck_password*]
#   (Optional) The password for the clustercheck user.
#   Defaults to hiera('mysql_clustercheck_password')
#
#
class tripleo::profile::pacemaker::clustercheck (
  $step                  = Integer(hiera('step')),
  $clustercheck_user     = 'clustercheck',
  $clustercheck_password = hiera('mysql_clustercheck_password'),
  $bind_address          = hiera('mysql_bind_host'),
) {

  if $step >= 1 {
    file { '/etc/sysconfig/clustercheck' :
      ensure  => file,
      mode    => '0600',
      owner   => 'mysql',
      group   => 'mysql',
      content => "MYSQL_USERNAME=${clustercheck_user}\n
MYSQL_PASSWORD='${clustercheck_password}'\n
MYSQL_HOST=localhost\n",
    }

    # the clustercheck service is run via xinet in the container
    xinetd::service { 'galera-monitor' :
      bind           => $bind_address,
      port           => '9200',
      server         => '/usr/bin/clustercheck',
      per_source     => 'UNLIMITED',
      log_on_success => '',
      log_on_failure => 'HOST',
      flags          => 'REUSE',
      service_type   => 'UNLISTED',
      user           => 'mysql',
      group          => 'mysql',
    }
  }
}
