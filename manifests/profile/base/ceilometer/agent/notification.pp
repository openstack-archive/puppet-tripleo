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
# == Class: tripleo::profile::base::ceilometer::agent::notification
#
# Ceilometer Notification Agent profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*notifier_enabled*]
#   (optional) Enable configuration of notifier as pipeline publisher.
#   Defaults to false
#
# [*notifier_events_enabled*]
#   (optional) Enable configuration of event notifier as pipeline publisher.
#   Defaults to false
#
# [*notifier_host_addr*]
#   (optional) IP address of Ceilometer notifier (edge qdr Endpoint)
#   Defaults to undef
#
# [*notifier_host_port*]
#   (optional) Ceilometer notifier port
#   Defaults to undef
#
# [*notifier_params*]
#   (optional) Query parameters for notifier URL
#   Defaults to {'driver' => 'amqp', 'topic' => 'ceilometer/metering.sample'}
#
# [*notifier_event_params*]
#   (optional) Query parameters for event notifier URL
#   Defaults to {'driver' => 'amqp', 'topic' => 'ceilometer/event.sample'}
#
# [*event_pipeline_publishers*]
#   (Optional) A list of event pipeline publishers
#   Defaults to undef
#
# [*pipeline_publishers*]
#   (Optional) A list of pipeline publishers
#   Defaults to undef
class tripleo::profile::base::ceilometer::agent::notification (
  $step                      = Integer(hiera('step')),
  $notifier_enabled          = false,
  $notifier_events_enabled   = false,
  $notifier_host_addr        = undef,
  $notifier_host_port        = undef,
  $notifier_params           = {'driver' => 'amqp', 'topic' => 'ceilometer/metering.sample'},
  $notifier_event_params     = {'driver' => 'amqp', 'topic' => 'ceilometer/event.sample'},
  $pipeline_publishers       = undef,
  $event_pipeline_publishers = undef,
) {
  include ::tripleo::profile::base::ceilometer
  include ::tripleo::profile::base::ceilometer::upgrade

  if $step >= 4 {
    include ::ceilometer::agent::auth

    if $pipeline_publishers {
      $other_publishers = Array($pipeline_publishers, true)
    } else {
      $other_publishers = []
    }
    if $notifier_enabled {
      $real_pipeline_publishers = $other_publishers + [os_transport_url({
        'transport' => 'notifier',
        'host'      => $notifier_host_addr,
        'port'      => $notifier_host_port,
        'query'     => $notifier_params,
      })]
    } else {
      $real_pipeline_publishers = $other_publishers
    }

    if $event_pipeline_publishers {
      $other_event_publishers = Array($event_pipeline_publishers, true)
    } else {
      $other_event_publishers = []
    }
    if $notifier_events_enabled {
      $real_event_pipeline_publishers = $other_event_publishers + [os_transport_url({
        'transport' => 'notifier',
        'host'      => $notifier_host_addr,
        'port'      => $notifier_host_port,
        'query'     => $notifier_event_params,
      })]
    } else {
      $real_event_pipeline_publishers = $other_event_publishers
    }

    class { '::ceilometer::agent::notification':
      event_pipeline_publishers => $real_event_pipeline_publishers,
      pipeline_publishers       => $real_pipeline_publishers,
    }
  }
}
