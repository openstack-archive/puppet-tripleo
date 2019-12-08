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
#
# [*mpm_module*]
#   The MPM module to use.
#   Default to prefork.

class tripleo::profile::base::apache(
  Boolean $enable_status_listener = false,
  String  $status_listener        = '127.0.0.1:80',
  String  $mpm_module             = 'prefork',
) {
  include apache::params
  # rhel8/fedora will be python3. See LP#1813053
  if ($::os['name'] == 'Fedora') or ($::os['family'] == 'RedHat' and Integer.new($::os['release']['major']) > 7) {
    class { 'apache':
      mod_packages => merge($::apache::params::mod_packages, { 'wsgi' =>  'python3-mod_wsgi' }),
      mod_libs     => merge($::apache::params::mod_libs, { 'wsgi' => 'mod_wsgi_python3.so' }),
      mpm_module   => $mpm_module,
    }
  } else {
    class { 'apache':
      mpm_module => $mpm_module,
    }
  }
  Service <| title == 'httpd' |> { provider => 'noop' }

  include apache::mod::status
  include apache::mod::ssl
  if $enable_status_listener {
    if !defined(Apache::Listen[$status_listener]) {
      ::apache::listen {$status_listener: }
    }
  }
}
