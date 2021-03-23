# Copyright 2021 Red Hat, Inc.
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
# == Class: tripleo::profile::base::cinder::backup::gcs
#
# Cinder Backup Google Cloud Service (GCS) profile for tripleo
#
# === Parameters
#
# [*credentials*]
#   (required) The GCS service account credentials, in JSON format.
#
# [*credential_file*]
#   (Optional) Absolute path of GCS service account credential file, to
#   be created with content from the credentials input.
#   Defaults to '/etc/cinder/gcs-backup.json'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::backup::gcs (
  $credentials,
  $credential_file = '/etc/cinder/gcs-backup.json',
  $step            = Integer(hiera('step')),
) {

  include tripleo::profile::base::cinder::backup

  if $step >= 4 {
    file { "${credential_file}" :
      ensure  => file,
      content => to_json_pretty($credentials),
      owner   => 'root',
      group   => 'cinder',
      mode    => '0640',
    }

    class { 'cinder::backup::google':
      backup_gcs_credential_file => $credential_file,
    }
  }

}
