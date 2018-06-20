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
# == Class: tripleo::profile::base::metrics::qdr
#
# Qpid dispatch router profile for tripleo
#
# === Parameters
#
# [*username*]
#   Username for the qdrouter daemon
#   Defaults to undef
#
# [*password*]
#   Password for the qdrouter daemon
#   Defaults to undef
#
# [*listener_addr*]
#   (optional) Service host name
#   Defaults to '127.0.0.1'
#
# [*listener_port*]
#   Service name or port number on which the qdrouterd will accept connections.
#   This argument must be string, even if the numeric form is used.
#   Defaults to '5666'
#
# [*listener_require_encrypt*]
#   (optional) Require the connection to the peer to be encrypted
#   Defaults to  'no'
#
# [*listener_require_ssl*]
#   (optional) Require the use of SSL or TLS on the connection
#   Defaults to 'no'
#
# [*listener_sasl_mech*]
#   (optional) List of accepted SASL auth mechanisms
#   Defaults to 'ANONYMOUS'
#
# [*listener_ssl_cert_db*]
#   (optional) Path to certificate db
#   Defaults to undef
#
# [*listener_ssl_cert_file*]
#   (optional) Path to certificat file
#   Defaults to undef
#
# [*listener_ssl_key_file*]
#   (optional) Path to private key file
#   Defaults to undef
#
# [*listener_ssl_pw_file*]
#   (optional) Path to password file for certificate key
#   Defaults to undef
#
# [*listener_ssl_password*]
#   (optional) Password to be supplied
#   Defaults to undef
#
# [*listener_trusted_certs*]
#   (optional) Path to file containing trusted certificates
#   Defaults to 'UNSET'
#
# [*connectors*]
#   (optional) List of hashes containing configuration for outgoing connections
#   from the router. Each hash should contain 'host', 'role' and 'port' key.
#   Defaults to []
#
# [*addresses*]
#   (optional) List of hashes containing configuration for addresses.
#   Defaults to []
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::metrics::qdr (
  $username                 = undef,
  $password                 = undef,
  $listener_addr            = 'localhost',
  $listener_port            = '5666',
  $listener_require_ssl     = false,
  $listener_require_encrypt = false,
  $listener_sasl_mech       = undef,
  $listener_ssl_cert_db     = undef,
  $listener_ssl_cert_file   = undef,
  $listener_ssl_key_file    = undef,
  $listener_ssl_pw_file     = undef,
  $listener_ssl_password    = undef,
  $listener_trusted_certs   = undef,
  $connectors               = [],
  $addresses                = [],
  $step                     = Integer(hiera('step')),
) {
  if $step >= 1 {
    class { '::qdr':
      listener_addr            => $listener_addr,
      listener_port            => $listener_port,
      listener_require_encrypt => $listener_require_encrypt,
      listener_require_ssl     => $listener_require_ssl,
      listener_ssl_cert_db     => $listener_ssl_cert_db,
      listener_ssl_cert_file   => $listener_ssl_cert_file,
      listener_ssl_key_file    => $listener_ssl_key_file,
      listener_ssl_pw_file     => $listener_ssl_pw_file,
      listener_ssl_password    => $listener_ssl_password,
      listener_trusted_certs   => $listener_trusted_certs,
      # TO-DO(mmagr): Metrics QDRs gonna run in edge mode as soon as we will
      # have a newest version of qpid-dispatch-router. Until then we have to run
      # in interior mode
      #router_mode              => 'edge',
      router_mode              => 'interior',
      connectors               => $connectors,
      extra_addresses          => $addresses,
    }

    qdr_user { $username:
      ensure   => present,
      password => $password,
    }
  }
}
