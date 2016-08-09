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
# == Class: tripleo::profile::base::logging::fluentd
#
# FluentD configuration for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) String. The current step of the deployment
#   Defaults to hiera('step')
#
# [*fluentd_sources*]
#   (Optional) List of dictionaries. A list of sources for fluentd.
#
# [*fluentd_filters*]
#   (Optional) List of dictionaries. A list of filters for fluentd.
#
# [*fluentd_servers*]
#   (Optional) List of dictionaries. A list of destination hosts for
#   fluentd.  Each should be of the form {host=>'my.host.name',
#   'port'=>24224}
#
# [*fluentd_groups*]
#   (Optional) List of strings. Add the 'fluentd' user to these groups.
#
# [*fluentd_pos_file_path*]
#   (Optional) String.  Path to a directory that will be created
#   if it does not exist and made writable by the fluentd user.
#
# [*fluentd_use_ssl*]
#   (Optional) Boolean. If true, use the secure_forward plugin.
#
# [*fluentd_ssl_certificate*]
#   (Required if fluentd_use_ssl is true) PEM encoded certificate data from
#   for example "secure-forward-ca-generate".
#
# [*fluentd_shared_key*]
#   (Required if fluentd_use_ssl is true) Shared secret key for fluentd
#   secure-foward plugin.
#
# [*fluentd_listen_syslog*]
#   (Optional, default true) When true, fluentd will listen for syslog 
#   messages on a local UDP port.
#
# [*fluentd_syslog_port*]
#   (Optional, default 42185) Port on which fluentd should listen if
#   $fluentd_listen_syslog is true.
class tripleo::profile::base::logging::fluentd (
  $step = hiera('step', undef),
  $fluentd_sources = undef,
  $fluentd_filters = undef,
  $fluentd_servers = undef,
  $fluentd_groups = undef,
  $fluentd_pos_file_path = undef,
  $fluentd_use_ssl = undef,
  $fluentd_ssl_certificate = undef,
  $fluentd_shared_key = undef,
  $fluentd_listen_syslog = true,
  $fluentd_syslog_port = 42185
) {
  if $step == undef or $step >= 3 {
    include ::fluentd

    if $fluentd_groups {
      user { $::fluentd::config_owner:
        ensure     => present,
        groups     => $fluentd_groups,
        membership => 'minimum',
      }
    }

    if $fluentd_pos_file_path {
      file { $fluentd_pos_file_path:
        ensure => 'directory',
        owner  => $::fluentd::config_owner,
        group  => $::fluentd::config_group,
        mode   => '0750',
      }
    }

    ::fluentd::plugin { 'rubygem-fluent-plugin-add':
      plugin_provider => 'yum',
    }

    if $fluentd_sources {
      ::fluentd::config { '100-openstack-sources.conf':
        config => {
          'source' => $fluentd_sources,
        }
      }
    }

    if $fluentd_listen_syslog {
      # fluentd will receive syslog messages by listening on a local udp
      # socket.
      ::fluentd::config { '110-system-sources.conf':
        config => {
          'source' => {
            'type' => 'syslog',
            'tag'  => 'system.messages',
            'port' => $fluentd_syslog_port,
          }
        }
      }

      file { '/etc/rsyslog.d/fluentd.conf':
        content => "*.* @127.0.0.1:${fluentd_syslog_port}",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
      } ~> exec { 'reload rsyslog':
        command => '/bin/systemctl restart rsyslog',
      }
    }

    if $fluentd_filters {
      ::fluentd::config { '200-openstack-filters.conf':
        config => {
          'filter' => $fluentd_filters,
        }
      }
    }

    if $fluentd_servers and !empty($fluentd_servers) {
      if $fluentd_use_ssl {
        ::fluentd::plugin { 'rubygem-fluent-plugin-secure-forward':
          plugin_provider => 'yum',
        }

        file {'/etc/fluentd/ca_cert.pem':
          content => $fluentd_ssl_certificate,
          owner   => $::fluentd::config_owner,
          group   => $::fluentd::config_group,
          mode    => '0444',
        }

        ::fluentd::config { '300-openstack-matches.conf':
          config => {
            'match' => {
              # lint:ignore:single_quote_string_with_variables
              # lint:ignore:quoted_booleans
              'type'          => 'secure_forward',
              'tag_pattern'   => '**',
              'self_hostname' => '${hostname}',
              'secure'        => 'true',
              'ca_cert_path'  => '/etc/fluentd/ca_cert.pem',
              'shared_key'    => $fluentd_shared_key,
              'server'        => $fluentd_servers,
              # lint:endignore
              # lint:endignore
            }
          }
        }
      } else {
        ::fluentd::config { '300-openstack-matches.conf':
          config => {
            'match' => {
              'type'        => 'forward',
              'tag_pattern' => '**',
              'server'      => $fluentd_servers,
            }
          }
        }
      }
    }
  }
}
