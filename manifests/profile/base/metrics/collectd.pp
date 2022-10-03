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
# == Class: tripleo::profile::base::metrics::collectd
#
# Collectd configuration for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*enable_file_logging*]
#   (Optional) Boolean. Whether to enable logfile plugin.
#   which we should send metrics.
#   Defaults to false
#
# [*collectd_server*]
#   (Optional) String. The name or address of a collectd server to
#   which we should send metrics.
#
# [*collectd_port*]
#   (Optional) Integer. The port to which we will connect on the
#   collectd server.
#
# [*collectd_username*]
#   (Optional) String.  Username for authenticating to the remote
#   collectd server.
#
# [*collectd_password*]
#   (Optional) String. Password for authenticating to the remote
#   collectd server.
#
# [*collectd_securitylevel*]
#   (Optional) String.
#
# [*enable_sqlalchemy_collectd*]
#   (Optional) boolean.  enable SQLAlchemy-collectd plugin
#   defaults to false
#
# [*sqlalchemy_collectd_bind_host*]
#   (Optional) String. Hostname to listen on.  Defaults to 0.0.0.0
#
# [*sqlalchemy_collectd_log_messages*]
#   (Optional) String. Log level for the plugin, set to "debug" to show
#   messages received.
#   Defaults to 'info'
#
# [*service_names*]
#   (Optional) List of strings.  A list of active services in this tripleo
#   deployment. This is used to look up service-specific plugins that
#   need to be installed.
#   Defaults to lookup('service_names', undef, undef, [])
#
# [*collectd_manage_repo*]
#   (Optional) Boolean. Whether let collectd enable manage repositories.
#   If it is set to true the epel repository will be used
#
# [*amqp_transport_name*]
#  (Optional) String. Name of the transport.
#  Default to 'metrics'
#
# [*amqp_host*]
#  (Optional) String. Hostname or IP address of the AMQP 1.0 intermediary.
#  Defaults to the undef
#
# [*amqp_port*]
#  (Optional) String. Service name or port number on which the AMQP 1.0
#  intermediary accepts connections. This argument must be a string,
#  even if the numeric form is used.
#  Defaults to undef
#
# [*amqp_user*]
#  (Optional) String. User part of credentials used to authenticate to the
#  AMQP 1.0 intermediary.
#  Defaults to undef
#
# [*amqp_password*]
#  (Optional) String. Password part of credentials used to authenticate
#  to the AMQP 1.0 intermediary.
#  Defaults to undef
#
# [*amqp_address*]
#  (Optional) String. This option specifies the prefix for the send-to value
#  in the message.
#  Defaults to 'collectd'
#
# [*amqp_retry_delay*]
#  (Optional) Number. When the AMQP1 connection is lost, defines the time
#  in seconds to wait before attempting to reconnect. If not set 1 second
#  is the implicit default.
#  Defaults to undef
#
# [*amqp_interval*]
#  (Optional) Number. Interval on which metrics should be sent to AMQP
#  intermediary. If not set the default for all collectd plugins is used.
#  Defaults to undef
#
# [*amqp_instances*]
#  (Optional) Hash of hashes. Each inner hash represent Instance block in plugin
#  configuration file. Key of outer hash represents instance name.
#  The 'address' value concatenated with the 'name' given will be used
#  as the send-to address for communications over the messaging link.
#  Defaults to {}.
#
# [*amqp_send_queue_limit*]
#  (Optional) Number. Number of data sets to be kept in memory, older sets
#  will be discarded; if set to undef, this feature is disabled.
#  Defaults to undef
#
# [*qdr_mode*]
#  (Optional) String. Mode in which the QDR service, to which collectd
#  should be connected, is running.
#  Defaults to lookup('tripleo::profile::base::metrics::qdr::router_mode', undef, undef, 'edge')
#
# [*python_read_plugins*]
#  (Optional) List of strings. List of third party python packages to install.
#  Defaults to [].
#
# [*enable_sensubility*]
#  (Optional) Boolean. Set to true if sensubility should be executed by exec plugin.
#  Defaults to false.
#
# [*enable_libpodstats*]
#  (Optional) Boolean. Set to true if the collectd libpodstats plugin should be
#  loaded
#  Defaults to false.
#
class tripleo::profile::base::metrics::collectd (
  $step = Integer(lookup('step')),
  $enable_file_logging = false,
  $collectd_server = undef,
  $collectd_port = undef,
  $collectd_username = undef,
  $collectd_password = undef,
  $collectd_securitylevel = undef,
  $enable_sqlalchemy_collectd = false,
  $sqlalchemy_collectd_bind_host = undef,
  $sqlalchemy_collectd_log_messages = undef,
  $amqp_transport_name = 'metrics',
  $amqp_host = undef,
  $amqp_port = undef,
  $amqp_user = undef,
  $amqp_password = undef,
  $amqp_address = 'collectd',
  $amqp_instances = {},
  $amqp_retry_delay = undef,
  $amqp_interval = undef,
  $amqp_send_queue_limit = undef,
  $qdr_mode = lookup('tripleo::profile::base::metrics::qdr::router_mode', undef, undef, 'edge'),
  $service_names = lookup('service_names', undef, undef, []),
  $collectd_manage_repo = false,
  $python_read_plugins = [],
  $enable_sensubility = false,
  $enable_libpodstats = false,
) {

  if $step >= 3 {
    if $enable_libpodstats {
        $typesdb = ['/usr/share/collectd/types.db', '/usr/share/collectd/types.db.libpodstats']
        include tripleo::profile::base::metrics::collectd::libpodstats
    } else {
        $typesdb = ['/usr/share/collectd/types.db']
    }

    class {'collectd':
      manage_repo => $collectd_manage_repo,
      typesdb     => $typesdb,
    }

    class { 'collectd::plugin::python':
      logtraces   => true,
    }

    $python_packages = $python_read_plugins
    package { $python_packages:
      ensure => 'present'
    }

    if $enable_file_logging {
      include collectd::plugin::logfile
    }

    if ! ($collectd_securitylevel in [undef, 'None', 'Sign', 'Encrypt']) {
      fail('collectd_securitylevel must be one of (None, Sign, Encrypt).')
    }

    # Load per-service plugin configuration
    ::tripleo::profile::base::metrics::collectd::collectd_service {
      $service_names: }

    # Because THT doesn't allow us to default values to undef, we need
    # to perform a number of transformations here to avoid passing a bunch of
    # empty strings to the collectd plugins.

    $_collectd_username = empty($collectd_username) ? {
      true    => undef,
      default => $collectd_username
    }

    $_collectd_password = empty($collectd_password) ? {
      true    => undef,
      default => $collectd_password
    }

    $_collectd_port = empty($collectd_port) ? {
      true    => undef,
      default => $collectd_port
    }

    $_collectd_securitylevel = empty($collectd_securitylevel) ? {
      true    => undef,
      default => $collectd_securitylevel
    }

    if $enable_sqlalchemy_collectd {
      ::tripleo::profile::base::metrics::collectd::sqlalchemy_collectd { 'sqlalchemy_collectd':
          bind_host    => $sqlalchemy_collectd_bind_host,
          log_messages => $sqlalchemy_collectd_log_messages,
      }
    }

    if ! empty($collectd_server) {
      ::collectd::plugin::network::server { $collectd_server:
        username      => $_collectd_username,
        password      => $_collectd_password,
        port          => $_collectd_port,
        securitylevel => $_collectd_securitylevel,
      }
    } elsif !empty($amqp_host) {
      class { 'collectd::plugin::amqp1':
        ensure           => 'present',
        manage_package   => true,
        transport        => $amqp_transport_name,
        host             => $amqp_host,
        port             => $amqp_port,
        user             => $amqp_user,
        password         => $amqp_password,
        address          => $amqp_address,
        instances        => $amqp_instances,
        retry_delay      => $amqp_retry_delay,
        interval         => $amqp_interval,
        send_queue_limit => $amqp_send_queue_limit,
      }
    }
    if $enable_sensubility {
      include tripleo::profile::base::metrics::collectd::sensubility
    }
  }
}
