# Copyright 2018 Red Hat, Inc.
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
# == Define: tripleo::profile::base::metrics::collectd::sensubility
#
# This is used to create configuration file for collectd-sensubility plugin
#
# === Parameters
#
# [*ensure*]
#   (Optional) String. Action to perform with sensubility plugin
#   configuration file.
#   Defaults to 'present'
#
# [*config_path*]
#  (Optional) String. Path to configuration file, which should be populated.
#  Defaults to '/etc/collectd-sensubility.conf'.
#
# [*log_file*]
#  (Optional) String. Override default log file path (/var/log/collectd/sensubility.log).
#  Defaults to undef.
#
# [*log_level*]
#  (Optional) String. Override default logging level (WARN).
#  Defaults to undef.
#
# [*connection*]
#  (Optional) String. URL to Sensu sever side (be default "ampq://sensu:sensu@localhost:5672//sensu")
#  Defaults to undef.
#
# [*subscriptions*]
#  (Optional) List of strings. List of channels to subscribe to.
#  Defaults to undef.
#
# [*client_name*]
#  (Optional) String. Name of the client displayed on Sensu server side (by default COLLECTD_HOSTNAME env or hostname).
#  Defaults to undef.
#
# [*client_address*]
#  (Optional) String. Address of the client displayed on Sensu server side (by default IP address of host).
#  Defaults to undef.
#
# [*keepalive_interval*]
#  (Optional) Integer. Interval in seconds for sending keepalive messages to Sensu server side (By default 20).
#  Defaults to undef.
#
# [*tmp_base_dir*]
#  (Optional) String. Path to temporary directory which is used for creation of check scripts
#  (by default /var/tmp/collectd-sensubility-checks).
#  Defaults to undef.
#
# [*shell_path*]
#  (Optional) String. Path to shell used for executing check scripts (by default /usr/bin/sh).
#  Defaults to undef.
#
# [*worker_count*]
#  (Optional) String. Number of goroutines spawned for executing check scripts (by default 2).
#  Defaults to undef.
#
# [*checks*]
#  (Optional) Hash representing definitions of standalone checks (by default {}).
#  Defaults to undef.
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
# [*exec_user*]
#  (Optional) String. User under which sensubility is executed via collectd-exec.
#  Defaults to 'collectd'
#
# [*exec_group*]
#  (Optional) String. Group under which sensubility is executed via collectd-exec.
#  Defaults to 'collectd'
#
# [*exec_sudo_rule*]
#  (Optional) String. Rule which will be saved in /etc/sudoers.d for user specified
#  by parameter exec_user.
#  Defaults to undef
#
# [*results_format*]
#  (Optional) String. Set message format compatability. Options are
#  [smartgateway,sensu]
#  Defaults to smartgateway
#
# [*results_channel*]
#  String. Target AMQP1 channel address to which messages should be sent
#  Defaults to undef
#
# [*transport*]
#  String. Bus type for message transport. Options are 'sensu' (rabbitmq) or 'amqp1'
#  Defaults to 'sensu'
class tripleo::profile::base::metrics::collectd::sensubility (
  $ensure             = 'present',
  $config_path        = '/etc/collectd-sensubility.conf',
  $log_file           = undef,
  $log_level          = undef,
  $connection         = undef,
  $subscriptions      = undef,
  $client_name        = undef,
  $client_address     = undef,
  $keepalive_interval = undef,
  $tmp_base_dir       = undef,
  $shell_path         = undef,
  $worker_count       = undef,
  $checks             = undef,
  $amqp_host          = undef,
  $amqp_port          = undef,
  $amqp_user          = undef,
  $amqp_password      = undef,
  $exec_user          = 'collectd',
  $exec_group         = 'collectd',
  $exec_sudo_rule     = undef,
  $results_format     = 'smartgateway',
  $results_channel    = undef,
  $transport          = 'sensu'
) {
  include ::collectd
  include ::collectd::plugin::exec

  package { 'collectd-sensubility':
    ensure => $ensure,
  }

  file { $config_path:
    ensure  => $ensure,
    mode    => '0644',
    content => epp('tripleo/metrics/collectd-sensubility.conf.epp', {
      log_file           => $log_file,
      log_level          => $log_level,
      connection         => $connection,
      subscriptions      => $subscriptions,
      client_name        => $client_name,
      client_address     => $client_address,
      keepalive_interval => $keepalive_interval,
      tmp_base_dir       => $tmp_base_dir,
      shell_path         => $shell_path,
      worker_count       => $worker_count,
      checks             => inline_template('<%= @checks.to_json %>'),
      amqp_host          => $amqp_host,
      amqp_port          => $amqp_port,
      amqp_user          => $amqp_user,
      amqp_password      => $amqp_password,
      results_format     => $results_format,
      results_channel    => $results_channel,
      transport          => $transport
    })
  }

  collectd::plugin::exec::cmd { 'sensubility':
    user  => $exec_user,
    group => $exec_group,
    exec  => ['collectd-sensubility'],
  }

  if $exec_sudo_rule {
    $sudoers_path = "/etc/sudoers.d/sensubility_${exec_user}"
    file { $sudoers_path:
      ensure  => $ensure,
      mode    => '0440',
      content => "${exec_user}  ${exec_sudo_rule}",
      notify  => Exec["${exec_user}-sudo-syntax-check"]
    }

    exec { "${exec_user}-sudo-syntax-check":
      path        => ['/usr/sbin/', '/usr/bin/'],
      command     => "visudo -c -f '${sudoers_path}' || (rm -f '${sudoers_path}' && exit 1)",
      refreshonly => true,
    }
  }

}
