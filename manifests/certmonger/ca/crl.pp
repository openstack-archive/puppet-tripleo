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
# == class: tripleo::certmonger::ca::crl
#
# Class that downloads the appropriate CRL file from the CA. This can
# furtherly be used by services in order for proper certificate revocation to
# come into effect. The class also sets up a cron job that will refresh the CRL
# once a week. Also, processing of the CRL file might be needed. e.g. most CAs
# use DER format to distribute the CRLs, while services such as HAProxy expect
# the CRL to be in PEM format.
#
# === Parameters
#
# [*crl_dest*]
#   (Optional) The file where the CRL file will be stored.
#   Defaults to '/etc/pki/CA/crl/overcloud-crl.pem'
#
# [*crl_source*]
#   (Optional) The URI where the CRL file will be fetched from.
#   Defaults to undef
#
# [*process*]
#   (Optional) Whether the CRL needs processing before being used. This means
#   transforming from DER to PEM format or viceversa. This is because most CRLs
#   by default come in DER format, so most likely it needs to be transformed.
#   Defaults to true
#
# [*crl_preprocessed*]
#   (Optional) The pre-processed CRL file which will be transformed.
#   Defaults to '/etc/pki/CA/crl/overcloud-crl.bin'
#
# [*crl_preprocessed_format*]
#   (Optional) The pre-processed CRL file's format which will be transformed.
#   Defaults to 'DER'
#
#  [*minute*]
#   (optional) Defaults to '0'.
#
#  [*hour*]
#   (optional) Defaults to '*/2'.
#
#  [*monthday*]
#   (optional) Defaults to '*'.
#
#  [*month*]
#   (optional) Defaults to '*'.
#
#  [*weekday*]
#   (optional) Defaults to '6'.
#
#  [*maxdelay*]
#   (optional) Seconds. Defaults to 0. Should be a positive integer.
#   Induces a random delay before running the cronjob to avoid running all
#   cron jobs at the same time on all hosts this job is configured.
#
# [*reload_cmds*]
#   (Optional) list of commands to be executed after fetching the CRL list in
#   the cron job. This will usually be a list of reload commands issued to
#   services that use the CRL.
#   Defaults to []
#
class tripleo::certmonger::ca::crl (
  $crl_dest                   = '/etc/pki/CA/crl/overcloud-crl.pem',
  $crl_source                 = undef,
  $process                    = true,
  $crl_preprocessed           = '/etc/pki/CA/crl/overcloud-crl.bin',
  $crl_preprocessed_format    = 'DER',
  $minute                     = '0',
  $hour                       = '*/2',
  $monthday                   = '*',
  $month                      = '*',
  $weekday                    = '*',
  $maxdelay                   = 0,
  $reload_cmds                = [],
) {
  if $crl_source {
    $ensure = 'present'
  } else {
    $ensure = 'absent'
  }

  if $maxdelay == 0 {
    $sleep = ''
  } else {
    $sleep = "sleep `expr \${RANDOM} \\% ${maxdelay}`; "
  }

  if $process {
    $fetched_crl = $crl_preprocessed
  } else {
    $fetched_crl = $crl_dest
  }

  file { 'tripleo-ca-crl' :
    ensure => $ensure,
    path   => $fetched_crl,
    source => $crl_source,
    mode   => '0644',
  }

  if $process and $ensure == 'present' {
    $crl_dest_format = $crl_preprocessed_format ? {
      'PEM' => 'DER',
      'DER' => 'PEM'
    }
    # transform CRL from DER to PEM or viceversa
    $process_cmd = "openssl crl -in ${$crl_preprocessed} -inform ${crl_preprocessed_format} -outform ${crl_dest_format} -out ${crl_dest}"
    exec { 'tripleo-ca-crl-process-command' :
      command     => $process_cmd,
      path        => '/usr/bin',
      refreshonly => true,
      subscribe   => File['tripleo-ca-crl']
    }
  } else {
    $process_cmd = []
  }

  if $ensure == 'present' {
    # Fetch CRL in cron job and notify needed services
    $cmd_list = concat(["${sleep}curl -g -s -L -o ${fetched_crl} ${crl_source}"], $process_cmd, $reload_cmds)
    $cron_cmd = join($cmd_list, ' && ')
  } else {
    $cron_cmd = absent
  }

  cron { 'tripleo-refresh-crl-file':
    ensure      => $ensure,
    command     => $cron_cmd,
    environment => 'PATH=/usr/bin:/bin SHELL=/bin/sh',
    user        => 'root',
    minute      => $minute,
    hour        => $hour,
    monthday    => $monthday,
    month       => $month,
    weekday     => $weekday,
  }
}
