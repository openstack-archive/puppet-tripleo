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
# == Class: tripleo::profile::base::haproxy
#
# Loadbalancer profile for tripleo
#
# === Parameters
#
# [*enable_ssl*]
#   (Optional) Whether SSL should be used for the connection to the server or
#   not.
#   Defaults to false
#
# [*mysql_read_default_file*]
#   (Optional) Name of the file that will be passed to pymysql connection strings
#   Defaults to '/etc/my.cnf.d/tripleo.cnf'
#
# [*mysql_read_default_group*]
#   (Optional) Name of the ini section to be passed to pymysql connection strings
#   Defaults to 'tripleo'
#
# [*mysql_client_bind_address*]
#   (Optional) Client IP address of the host that will be written in the mysql_read_default_file
#   Defaults to undef
#
# [*ssl_ca*]
#   (Optional) The SSL CA file to use to verify the MySQL server's certificate.
#   Defaults to '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::database::mysql::client (
  $enable_ssl                = false,
  $mysql_read_default_file   = '/etc/my.cnf.d/tripleo.cnf',
  $mysql_read_default_group  = 'tripleo',
  $mysql_client_bind_address = undef,
  $ssl_ca                    = '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt',
  $step                      = Integer(lookup('step')),
) {
  if $step >= 1 {
    if $mysql_client_bind_address =~ Stdlib::Compat::Ip_address {
      $client_bind_changes = [
        "set ${mysql_read_default_group}/bind-address '${mysql_client_bind_address}'"
      ]
    } else {
      $client_bind_changes = [
        "rm ${mysql_read_default_group}/bind-address"
      ]
    }

    if $enable_ssl {
      $changes_ssl = [
        "set ${mysql_read_default_group}/ssl '1'",
        "set ${mysql_read_default_group}/ssl-ca '${ssl_ca}'",
        'set client/ssl \'1\'',
        "set client/ssl-ca '${ssl_ca}'"
      ]
    } else {
      $changes_ssl = [
        "rm ${mysql_read_default_group}/ssl",
        "rm ${mysql_read_default_group}/ssl-ca",
        'rm client/ssl',
        'rm client/ssl-ca'
      ]
    }

    $conf_changes = union($client_bind_changes, $changes_ssl)

    # When generating configuration with docker-puppet, services do
    # not include any profile that would ensure creation of /etc/my.cnf.d,
    # so we enforce the check here.
    file {'/etc/my.cnf.d':
      ensure => 'directory'
    }
    file { $mysql_read_default_file:
      ensure => file,
    }
    augeas { 'tripleo-mysql-client-conf':
      incl    => $mysql_read_default_file,
      lens    => 'Puppet.lns',
      changes => $conf_changes,
      require => File[$mysql_read_default_file],
    }

    # If a profile created a file resource for the parent directory,
    # ensure it is being run before the config file generation
    File<| title == '/etc/my.cnf.d' |> -> Augeas['tripleo-mysql-client-conf']
  }
}
