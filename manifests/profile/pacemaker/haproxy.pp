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
# == Class: tripleo::profile::pacemaker::haproxy
#
# HAproxy with Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('haproxy_short_bootstrap_node_name')
#
# [*enable_load_balancer*]
#   (Optional) Whether load balancing is enabled for this cluster
#   Defaults to hiera('enable_load_balancer', true)
#
# [*manage_firewall*]
#  (optional) Enable or disable firewall settings for ports exposed by HAProxy
#  (false means disabled, and true means enabled)
#  Defaults to hiera('tripleo::firewall::manage_firewall', true)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
class tripleo::profile::pacemaker::haproxy (
  $bootstrap_node       = hiera('haproxy_short_bootstrap_node_name'),
  $enable_load_balancer = hiera('enable_load_balancer', true),
  $manage_firewall      = hiera('tripleo::firewall::manage_firewall', true),
  $step                 = Integer(hiera('step')),
  $pcs_tries            = hiera('pcs_tries', 20),
) {
  class {'::tripleo::profile::base::haproxy':
    manage_firewall => $manage_firewall,
  }

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $step >= 1 and $pacemaker_master and hiera('stack_action') == 'UPDATE' and $enable_load_balancer {
    tripleo::pacemaker::resource_restart_flag { 'haproxy-clone':
      subscribe => Concat['/etc/haproxy/haproxy.cfg'],
    }
  }

  if $step >= 2 and $enable_load_balancer {
    pacemaker::property { 'haproxy-role-node-property':
      property => 'haproxy-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
    if $pacemaker_master {
      $haproxy_location_rule = {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['haproxy-role eq true'],
      }
      # FIXME: we should not have to access tripleo::haproxy class
      # parameters here to configure pacemaker VIPs. The configuration
      # of pacemaker VIPs could move into puppet-tripleo or we should
      # make use of less specific hiera parameters here for the settings.
      pacemaker::resource::service { 'haproxy':
        op_params     => 'start timeout=200s stop timeout=200s',
        clone_params  => true,
        location_rule => $haproxy_location_rule,
        tries         => $pcs_tries,
        require       => Pacemaker::Property['haproxy-role-node-property'],
      }

      $control_vip = hiera('controller_virtual_ip')
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_control_vip':
        vip_name      => 'control',
        ip_address    => $control_vip,
        location_rule => $haproxy_location_rule,
        pcs_tries     => $pcs_tries,
        require       => Pacemaker::Property['haproxy-role-node-property'],
      }

      $public_vip = hiera('public_virtual_ip')
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_public_vip':
        ensure        => $public_vip and $public_vip != $control_vip,
        vip_name      => 'public',
        ip_address    => $public_vip,
        location_rule => $haproxy_location_rule,
        pcs_tries     => $pcs_tries,
        require       => Pacemaker::Property['haproxy-role-node-property'],
      }

      $redis_vip = hiera('redis_vip')
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_redis_vip':
        ensure        => $redis_vip and $redis_vip != $control_vip,
        vip_name      => 'redis',
        ip_address    => $redis_vip,
        location_rule => $haproxy_location_rule,
        pcs_tries     => $pcs_tries,
        require       => Pacemaker::Property['haproxy-role-node-property'],
      }

      # Set up all vips for isolated networks
      $network_vips = hiera('network_virtual_ips', {})
      $network_vips.each |String $net_name, $vip_info| {
        $virtual_ip = $vip_info[ip_address]
        tripleo::pacemaker::haproxy_with_vip {"haproxy_and_${net_name}_vip":
          ensure        => $virtual_ip and $virtual_ip != $control_vip,
          vip_name      => $net_name,
          ip_address    => $virtual_ip,
          location_rule => $haproxy_location_rule,
          pcs_tries     => $pcs_tries,
          require       => Pacemaker::Property['haproxy-role-node-property'],
        }
      }
    }
  }

}
