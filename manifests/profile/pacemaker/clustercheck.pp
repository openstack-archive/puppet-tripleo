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
# [*post_status_wait*]
#   (Optional) Number of seconds to wait after status is returned.
#   This is only useful for slow environments where haproxy may report
#   a "socket error" after clustercheck status is returned if it cannot
#   poll and close its side of the connection before socat does.
#   Defaults to 0
#
#
class tripleo::profile::pacemaker::clustercheck (
  $step                  = Integer(hiera('step')),
  $clustercheck_user     = 'clustercheck',
  $clustercheck_password = hiera('mysql_clustercheck_password'),
  $bind_address          = hiera('mysql_bind_host'),
  $post_status_wait      = 0,
) {

  if $step >= 1 {
    # configuration used by the galera resource agent,
    # and by the clustercheck service when it is configured
    # to listen via socat
    if $bind_address =~ Stdlib::Compat::Ipv6 {
      $socat_listen_type = 'tcp6-listen'
    } else {
      $socat_listen_type = 'tcp4-listen'
    }
    file { '/etc/sysconfig/clustercheck' :
      ensure  => file,
      mode    => '0600',
      owner   => 'mysql',
      group   => 'mysql',
      content => "MYSQL_USERNAME=${clustercheck_user}\n
MYSQL_PASSWORD='${clustercheck_password}'\n
MYSQL_HOST=localhost\n
TRIPLEO_SOCAT_BIND='${socat_listen_type}:9200,bind=\"${bind_address}\",reuseaddr,fork'\n
TRIPLEO_POST_STATUS_WAIT=${post_status_wait}\n",
    }

    # configuration used when clustercheck is run via xinet
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
