# Copyright 2017 Camptocamp SA.
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
# == Class tripleo::profile::base::apache
#
# Common apache modules and configurationfor API listeners
#
# === Parameters
#
# [*enable_status_listener*]
#   Enable or not the localhost listener in httpd.
#   Accepted values: Boolean.
#   Default to false.
#
# [*status_listener*]
#   Where should apache listen for status page
#   Default to 127.0.0.1:80


class tripleo::profile::base::apache(
  Boolean $enable_status_listener = false,
  String  $status_listener        = '127.0.0.1:80',
) {
  include ::apache::mod::status
  include ::apache::mod::ssl

  # Automatic restart
  ::systemd::dropin_file { 'httpd.conf':
    unit    => 'httpd.service',
    content => "[Service]\nRestart=always\n",
  }

  if $enable_status_listener {
    if !defined(Apache::Listen[$status_listener]) {
      ::apache::listen {$status_listener: }
    }
  }
}
