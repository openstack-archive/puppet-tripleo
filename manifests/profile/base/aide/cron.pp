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
# == Class: tripleo::profile::base::aide::cron
#
# Aide cron profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*aide_command*]
#   Path to aide binary
#
# [*aide_cron_user*]
#   User for cron job to run aide
#   Defaults to 'root'
#
# [*aide_hour*]
#   The hour value used for cron entry
#   Defaults to 3
#
# [*aide_minute*]
#   The minute value used for cron entry
#   Defaults to 0
#
# [*aide_email*]
#   Send AIDE reports generated with cron job to this email address
#   Defaults to undef
#
# [*aide_mua_path*]
#   Use the following path to a MUA client to send email
#   Defaults to mailx
#
class tripleo::profile::base::aide::cron (
  $step           = Integer(hiera('step')),
  $aide_command   = '/usr/sbin/aide',
  $aide_cron_user = hiera('aide_cron_user', 'root'),
  $aide_hour      = hiera('aide_hour', 3),
  $aide_minute    = hiera('aide_minute', 0),
  $aide_email     = hiera('aide_email', undef),
  $aide_mua_path  = hiera('aide_mua_path', '/bin/mailx')
  ) {

  include ::tripleo::profile::base::aide

  if '@' in $aide_email {
    $cron_entry = "${aide_command} --check --config ${::tripleo::profile::base::aide::aide_conf_path} | ${aide_mua_path} \
-s \"\$HOSTNAME - AIDE integrity check\" ${aide_email}"
  }
  else {
    $cron_entry = "${aide_command} --check --config ${::tripleo::profile::base::aide::aide_conf_path} \
> /var/log/audit/aide_`date +%Y-%m-%d`.log"
  }

  cron { 'aide':
    command => $cron_entry,
    user    => $aide_cron_user,
    hour    => $aide_hour,
    minute  => $aide_minute,
    require => [Package['aide'], Exec['install aide db']]
  }
}
