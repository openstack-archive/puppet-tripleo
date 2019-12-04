# Copyright 2019 Red Hat, Inc.
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
# == Class: tripleo::profile::base::logging::rsyslog
#
# rsyslogd configuration for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) String. The current step of the deployment
#   Defaults to hiera('step')
#
# [*service_names*]
#   (Optional) List of services enabled on the current role. This is used
#   to obtain per-service configuration information.
#   Defaults to hiera('service_names', [])
#
# [*elasticsearch*]
#   (Optional) Hash. Configuration for output plugin omelasticsearch.
#   Defaults to undef
#
# [*elasticsearch_tls_ca_cert*]
#   (Optional) String. Contains content of the CA cert for the CA that issued
#   Elasticsearch server cert.
#   Defaults to undef
#
# [*elasticsearch_tls_client_cert*]
#   (Optional) String. Contains content of the client cert for doing client
#   cert auth against Elasticsearch.
#   Defaults to undef
#
# [*elasticsearch_tls_client_key*]
#   (Optional) String. Contains content of the private key corresponding to
#   the cert elasticsearch_tls_client_cert.
#   Defaults to undef
class tripleo::profile::base::logging::rsyslog (
  $step                          = Integer(hiera('step')),
  $service_names                 = hiera('service_names', []),
  $elasticsearch                 = undef,
  $elasticsearch_tls_ca_cert     = undef,
  $elasticsearch_tls_client_cert = undef,
  $elasticsearch_tls_client_key  = undef,
) {
  if $step >= 2 {
    # NOTE: puppet-rsyslog does not have params manifest, so we don't have any
    #       other choice than using hiera currently.
    $rsyslog_confdir = hiera('rsyslog::confdir', '/etc/rsyslog.d')

    if defined('$elasticsearch_tls_ca_cert') {
      $cacert_path = "${rsyslog_confdir}/es-ca-cert.crt"
      $cacert_conf = {'tls.cacert' => $cacert_path}

      file { 'elasticsearch_ca_cert':
        ensure  => 'present',
        path    => $cacert_path,
        content => $elasticsearch_tls_ca_cert
      }
      $esconf1 = merge($elasticsearch, $cacert_conf)
    } else {
      $esconf1 = $elasticsearch
    }

    if defined('$elasticsearch_tls_client_cert') {
      $clientcert_path = "${rsyslog_confdir}/es-client-cert.pem"
      $clientcert_conf = {'tls.mycert' => $clientcert_path}

      file { 'elasticsearch_client_cert':
        ensure  => 'present',
        path    => $clientcert_path,
        content => $elasticsearch_tls_client_cert
      }
      $esconf2 = merge($esconf1, $clientcert_conf)
    } else {
      $esconf2 = $esconf1
    }

    if defined('$elasticsearch_tls_client_key') {
      $clientkey_path = "${rsyslog_confdir}/es-client-key.pem"
      $clientkey_conf = {'tls.myprivkey' => $clientkey_path}

      file { 'elasticsearch_client_key':
        ensure  => 'present',
        path    => $clientkey_path,
        content => $elasticsearch_tls_client_key
      }
      $esconf = merge($esconf2, $clientkey_conf)
    } else {
      $esconf = $esconf2
    }

    $modules = {
      'imfile'          => {},
      'omelasticsearch' => {},
    }
    $actions = {
      'elasticsearch' => {
        'type'   => 'omelasticsearch',
        'config' => $esconf,
      }
    }

    class { '::rsyslog::server':
      modules => $modules,
      actions => $actions
    }
    tripleo::profile::base::logging::rsyslog::file_input{$service_names: }
  }
}
