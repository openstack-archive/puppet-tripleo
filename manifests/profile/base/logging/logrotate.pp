# Copyright 2017 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::logging::logrotate
#
# Installs a cron job that rotates containerized services logs.
#
# === Parameters
#
#  [*step*]
#    (Optional) String. The current step of the deployment
#    Defaults to Integer(lookup('step'))
#
#  [*ensure*]
#    (Optional) Status of the cron job. Valid values are present, absent.
#    Defaults to present.
#
#  [*minute*]
#    (Optional) Defaults to '0'. Configures cron job for logrotate.
#
#  [*hour*]
#    (Optional) Defaults to '*'. Configures cron job for logrotate.
#
#  [*monthday*]
#    (Optional) Defaults to '*'. Configures cron job for logrotate.
#
#  [*month*]
#    (Optional) Defaults to '*'. Configures cron job for logrotate.
#
#  [*weekday*]
#    (Optional) Defaults to '*'. Configures cron job for logrotate.
#
#  [*maxdelay*]
#    (Optional) Seconds. Defaults to 90. Should be a positive integer.
#    Induces a random delay before running the cronjob to avoid running all
#    cron jobs at the same time on all hosts this job is configured.
#
#  [*user*]
#    (Optional) Defaults to 'root'. Configures cron job for logrotate.
#
#  [*copytruncate*]
#    (Optional) Defaults to True.
#    Configures the logrotate copytruncate parameter.
#
#  [*delaycompress*]
#    (Optional) Defaults to True.
#    Configures the logrotate delaycompress parameter.
#
#  [*compress*]
#    (Optional) Defaults to True.
#    Configures the logrotate compress parameter.
#
#  [*minsize*]
#    (Optional) Defaults to '1'.
#    Configures the logrotate minsize parameter.
#
#  [*maxsize*]
#    (Optional) Defaults to '10M'.
#    Configures the logrotate maxsize parameter.
#
#  [*notifempty*]
#    (Optional) Defaults to True.
#    Configures the logrotate notifempty parameter.
#
#  [*rotation*]
#    (Optional) Defaults to 'daily'.
#    Configures the logrotate rotation interval.
#
#  [*rotate*]
#    (Optional) Defaults to 14.
#    Configures the logrotate rotate parameter.
#
#  [*purge_after_days*]
#    (Optional) Defaults to 14.
#    Configures forced purge period for rotated logs.
#    Overrides the rotation and rotate settings.
#
#  [*dateext*]
#    (Optional) Defaults to undef.
#    Configures the dateext parameter.
#
#  [*dateformat*]
#    (Optional) Defaults to undef.
#    Configures the dateformat parameter used with dateext parameter.
#
#  [*dateyesterday*]
#    (Optional) Defaults to undef.
#    Configures the dateyesterday parameter used with dateext parameter.
#
# DEPRECATED PARAMETERS
#
#  [*size*]
#    DEPRECATED: (Optional) Defaults to '10M'.
#    Configures the logrotate size parameter.
#
class tripleo::profile::base::logging::logrotate (
  $step             = Integer(lookup('step')),
  $ensure           = present,
  $minute           = 0,
  $hour             = '*',
  $monthday         = '*',
  $month            = '*',
  $weekday          = '*',
  Integer $maxdelay = 90,
  $user             = 'root',
  $copytruncate     = true,
  $delaycompress    = true,
  $compress         = true,
  $rotation         = 'daily',
  $minsize          = 1,
  $maxsize          = '10M',
  $notifempty       = true,
  $rotate           = 14,
  $purge_after_days = 14,
  $dateext          = undef,
  $dateformat       = undef,
  $dateyesterday    = undef,
  # DEPRECATED PARAMETERS
  $size             = undef,
) {

  if $step >= 4 {
    if ($size != undef) {
      warning('The size parameter is DISABLED to enforce GDPR.')
      warning('Size configures maxsize instead of size.')
      $maxsize = pick($size, $maxsize)
    }
    if $maxdelay == 0 {
      $sleep = ''
    } else {
      $sleep = "sleep `expr \${RANDOM} \\% ${maxdelay}`; "
    }

    $svc = 'logrotate-crond'
    $config = "/etc/${svc}.conf"
    $state = "/var/lib/logrotate/${svc}.status"
    $cmd = "${sleep}/usr/sbin/logrotate -s ${state} ${config}"

    file { "${config}":
      ensure  => $ensure,
      owner   => $user,
      group   => $user,
      mode    => '0640',
      content => template('tripleo/logrotate/containers_logrotate.conf.erb'),
    }

    cron { "${svc}":
      ensure      => $ensure,
      command     => "${cmd} 2>&1|logger -t ${svc}",
      environment => 'PATH=/bin:/usr/bin:/usr/sbin SHELL=/bin/sh',
      user        => $user,
      minute      => $minute,
      hour        => $hour,
      monthday    => $monthday,
      month       => $month,
      weekday     => $weekday,
    }
  }
}
