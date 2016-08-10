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
# == Class: tripleo::profile::base::rabbitmq
#
# RabbitMQ profile for tripleo
#
# === Parameters
#
# [*config_variables*]
#   (Optional) RabbitMQ environment.
#   Defaults to hiera('rabbitmq_config_variables').
#
# [*environment*]
#   (Optional) RabbitMQ environment.
#   Defaults to hiera('rabbitmq_environment').
#
# [*ipv6*]
#   (Optional) Whether to deploy RabbitMQ on IPv6 network.
#   Defaults to str2bool(hiera('rabbit_ipv6', false)).
#
# [*kernel_variables*]
#   (Optional) RabbitMQ environment.
#   Defaults to hiera('rabbitmq_environment').
#
# [*nodes*]
#   (Optional) Array of host(s) for RabbitMQ nodes.
#   Defaults to hiera('rabbitmq_node_ips', []).
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::rabbitmq (
  $config_variables = hiera('rabbitmq_config_variables'),
  $environment      = hiera('rabbitmq_environment'),
  $ipv6             = str2bool(hiera('rabbit_ipv6', false)),
  $kernel_variables = hiera('rabbitmq_kernel_variables'),
  $nodes            = hiera('rabbitmq_node_ips', []),
  $step             = hiera('step'),
) {
  # IPv6 environment, necessary for RabbitMQ.
  if $ipv6 {
    $rabbit_env = merge($environment, {
      'RABBITMQ_SERVER_START_ARGS' => '"-proto_dist inet6_tcp"'
    })
  } else {
    $rabbit_env = $environment
  }

  $manage_service = hiera('rabbitmq::service_manage', true)
  if $step >= 1 {
    # Specific configuration for multi-nodes or when running with Pacemaker.
    if count($nodes) > 1 or ! $manage_service {
      class { '::rabbitmq':
        config_cluster          => $manage_service,
        cluster_nodes           => $nodes,
        tcp_keepalive           => false,
        config_kernel_variables => $kernel_variables,
        config_variables        => $config_variables,
        environment_variables   => $rabbit_env,
      }
      # when running multi-nodes without Pacemaker
      if $manage_service {
        rabbitmq_policy { 'ha-all@/':
          pattern    => '^(?!amq\.).*',
          definition => {
            'ha-mode' => 'all',
          },
        }
      }
    } else {
      # Standard configuration
      class { '::rabbitmq':
        tcp_keepalive           => false,
        config_kernel_variables => $kernel_variables,
        config_variables        => $config_variables,
        environment_variables   => $rabbit_env,
      }
    }
  }

}
