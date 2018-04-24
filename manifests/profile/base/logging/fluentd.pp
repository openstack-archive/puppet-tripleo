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
# [*fluentd_manage_groups*]
#   (Optional) Boolean. If true, modify the group membership of the
#   fluentd_config_user using information provided by fluentd_groups
#   and the per-service configurations.
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
# [*fluentd_monitoring*]
#   (Optional, default true) When true, fluentd will have REST API interface
#   for monitoring purposes.
#
# [*fluentd_monitoring_bind*]
#   (Optional, default '127.0.0.1') Interface on which fluentd monitoring
#   interface should listen if $fluentd_monitoring is true.
#
# [*fluentd_monitoring_port*]
#   (Optional, default 24220) Port on which fluentd monitoring interface
#   should listen if $fluentd_monitoring is true.
#
# [*fluentd_listen_syslog*]
#   (Optional, default true) When true, fluentd will listen for syslog
#   messages on a local UDP port.
#
# [*fluentd_syslog_port*]
#   (Optional, default 42185) Port on which fluentd should listen if
#   $fluentd_listen_syslog is true.
#
# [*fluentd_path_transform*]
#   (Optional) List. Specifies [find, replace] arguments that will be
#   used to transform the 'path' value for logging sources using puppet's
#   regsubst function.
#
# [*fluentd_pos_file_path*]
#   (Optional) String.  Path to a directory that will be created
#   if it does not exist and made writable by the fluentd user.
#
# [*fluentd_default_format*]
#   (Optional) String. Default log format if not otherwise specified
#   in a log source definition.
#
# [*fluentd_service_user*]
#   (Optional) String. Username that will run the fluentd service.
#   This will be used to create a systemd drop-in for the fluentd
#   service that sets User explicitly.
#
# [*service_names*]
#   (Optional) List of services enabled on the current role. This is used
#   to obtain per-service configuration information.
class tripleo::profile::base::logging::fluentd (
  $step = Integer(hiera('step')),
  $fluentd_sources = undef,
  $fluentd_filters = undef,
  $fluentd_servers = undef,
  $fluentd_groups = undef,
  $fluentd_manage_groups = true,
  $fluentd_use_ssl = undef,
  $fluentd_ssl_certificate = undef,
  $fluentd_shared_key = undef,
  $fluentd_listen_syslog = true,
  $fluentd_syslog_port = 42185,
  $fluentd_path_transform = undef,
  $fluentd_pos_file_path = undef,
  $fluentd_default_format = undef,
  $fluentd_service_user = undef,
  $fluentd_monitoring = true,
  $fluentd_monitoring_bind = '127.0.0.1',
  $fluentd_monitoring_port = 24220,
  $service_names = hiera('service_names', [])
) {
  if $step >= 4 {
    include ::fluentd
    include ::systemd::systemctl::daemon_reload

    $_fluentd_service_user = pick($fluentd_service_user,
                                  $::fluentd::config_owner,
                                  'fluentd')

    # don't manage groups for 'root'
    $_fluentd_manage_groups = $_fluentd_service_user ? {
      'root'  => false,
      default => $fluentd_manage_groups,
    }

    ::systemd::dropin_file { 'fluentd_user.conf':
      unit    => "${::fluentd::service_name}.service",
      content => template('tripleo/fluentd/fluentd_user.conf.erb'),
    }
    ~> Service['fluentd']

    # Load per-service plugin configuration
    ::tripleo::profile::base::logging::fluentd::fluentd_service {
      $service_names:
        pos_file_path     => $fluentd_pos_file_path,
        default_format    => $fluentd_default_format,
        fluentd_transform => $fluentd_path_transform
    }

    if $_fluentd_manage_groups {
      # compute a list of all the groups of which the fluentd user
      # should be a member.
      $_tmpgroups1 = $service_names.map |$srv| {
          hiera("tripleo_fluentd_groups_${srv}", undef)
      }.filter |$new_srv| { ! empty($new_srv) }.flatten()

      $_tmpgroups2 = any2array($fluentd_groups)
      $groups = concat($_tmpgroups2,
        $_tmpgroups1)

      if !empty($groups) {
        Package<| tag == 'openstack' |>
        -> user { $_fluentd_service_user:
          ensure     => present,
          groups     => $groups,
          membership => 'minimum',
        }
        ~> Service[$::fluentd::service_name]
      }
    }

    if $fluentd_pos_file_path {
      file { $fluentd_pos_file_path:
        ensure  => 'directory',
        owner   => $_fluentd_service_user,
        group   => $::fluentd::config_group,
        mode    => '0750',
        recurse =>  true,
      }
      ~> Service[$::fluentd::service_name]
    }

    ::fluentd::plugin { 'rubygem-fluent-plugin-add':
      plugin_provider => 'yum',
    }

    if $fluentd_sources {

      if $fluentd_path_transform {
        $_fluentd_sources = map($fluentd_sources) |$source| {
          if $source['path'] {
            $newpath = {
              'path' => regsubst($source['path'],
                        $fluentd_path_transform[0],
                        $fluentd_path_transform[1])
            }

            $source + $newpath
          } else {
            $source
          }
        }
      } else {
        $_fluentd_sources = $fluentd_sources
      }

      ::fluentd::config { '100-openstack-sources.conf':
        config => {
          'source' => $_fluentd_sources,
        }
      }
    }

    if $fluentd_monitoring {
      # fluentd will open port for monitoring REST API interface
      ::fluentd::config { '110-monitoring-agent.conf':
        config => {
          'source' => {
            'type' => 'monitor_agent',
            'bind' => $fluentd_monitoring_bind,
            'port' => $fluentd_monitoring_port,
          }
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
        command     => '/bin/systemctl restart rsyslog',
        refreshonly => true,
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
          owner   => $_fluentd_service_user,
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
