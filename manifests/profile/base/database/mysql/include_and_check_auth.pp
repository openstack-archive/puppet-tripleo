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
# == Class: include_and_check_auth
#
# Include an OpenStack MySQL profile and configures it for alternative
# client authentication like e.g. ed25519
#
# === Parameters
#
# [*module*]
#   (Optional) The puppet module to include
#   Defaults to $title
#
# [*mysql_auth_ed25519*]
#   (Optional) Use MariaDB's ed25519 authentication plugin to authenticate
#   a user when connecting to the server
#   Defaults to hiera('mysql_auth_ed25519', false)
#
define tripleo::profile::base::database::mysql::include_and_check_auth(
  $module = $title,
  $mysql_auth_ed25519 = hiera('mysql_auth_ed25519', false),
) {
  include $module
  if ($mysql_auth_ed25519) {
    # currently all openstack puppet modules create MySQL users
    # by hashing their password for the default auth method.
    # If ed25519 auth is enabled, we must hash the password
    # differently; so do it with a collector until all
    # openstack modules support ed25519 auth natively.
    $stripped_module_name = regsubst($module,'^::','')
    $password_key = "${stripped_module_name}::password"
    Openstacklib::Db::Mysql<| tag == $stripped_module_name |> {
      plugin => 'ed25519',
      password_hash => mysql_ed25519_password(hiera($password_key))
    }
  }
}
