#
# Copyright (C) 2015 eNovance SAS <licensing@enovance.com>
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
# == Class: tripleo
#
# Configure the TripleO firewall
#
# === Parameters:
#
# [*manage_firewall*]
#  (optional) Completely enable or disable firewall settings
#  (false means disabled, and true means enabled)
#  Defaults to false
#
# [*firewall_chains*]
#   (optional) Manage firewall chains
#   Default to {}
#
# [*firewall_rules*]
#   (optional) Allow to add custom firewall rules
#   Should be an hash.
#   Default to {}
#
# [*purge_firewall_chains*]
#   (optional) Boolean, purge all firewalli rules in a given chain
#   Defaults to false
#
# [*purge_firewall_rules*]
#   (optional) Boolean, purge all firewall resources
#   Defaults to false
#
# [*firewall_pre_extras*]
#   (optional) Allow to add custom parameters to firewall rules (pre stage)
#   Should be an hash.
#   Default to {}
#
# [*firewall_post_extras*]
#   (optional) Allow to add custom parameters to firewall rules (post stage)
#   Should be an hash.
#   Default to {}
#
class tripleo::firewall(
  $manage_firewall       = false,
  $firewall_chains       = {},
  $firewall_rules        = {},
  $purge_firewall_chains = false,
  $purge_firewall_rules  = false,
  $firewall_pre_extras   = {},
  $firewall_post_extras  = {},
) {

  if $manage_firewall {

    if $purge_firewall_chains {
      resources { 'firewallchain':
        purge => true
      }
    }

    # Only purges IPv4 rules
    if $purge_firewall_rules {
      resources { 'firewall':
        purge => true
      }
    }

    # To manage the chains they must be named in specific ways
    # https://github.com/puppetlabs/puppetlabs-firewall#type-firewallchain
    # Example Hiera:
    # tripleo::firewall::firewall_chains:
    #   'FORWARD:filter:IPv4':
    #     ensure: present
    #     policy: accept
    #     purge: false
    #
    create_resources('firewallchain', $firewall_chains)

    # anyone can add your own rules
    # example with Hiera:
    #
    # tripleo::firewall::firewall_rules:
    #   '300 allow custom application 1':
    #     port: 999
    #     proto: udp
    #     action: accept
    #   '301 allow custom application 2':
    #     port: 8081
    #     proto: tcp
    #     action: accept
    #
    create_resources('tripleo::firewall::rule', $firewall_rules)

    ensure_resource('class', 'tripleo::firewall::pre', {
      'firewall_settings' => $firewall_pre_extras,
    })

    ensure_resource('class', 'tripleo::firewall::post', {
      'firewall_settings' => $firewall_post_extras,
    })

    Class['tripleo::firewall::pre'] -> Class['tripleo::firewall::post']
    Service<||> -> Class['tripleo::firewall::post']

    # Allow composable services to load their own custom
    # example with Hiera.
    # NOTE(dprince): In the future when we have a better hiera
    # heat hook we might refactor this to use hiera's merging
    # capabilities instead. Until then rolling up the flat service
    # keys and dynamically creating firewall rules for each service
    # will allow us to compose and should work fine.
    #
    # Each service can load its rules by using this form:
    #
    # tripleo.<service name with underscores>.firewall_rules:
    #   '300 allow custom application 1':
    #     dport: 999
    #     proto: udp
    #     action: accept
    $service_names = hiera('service_names', [])
    tripleo::firewall::service_rules { $service_names: }


    # puppetlabs-firewall only manages the current state of iptables
    # rules and writes out the rules to a file to ensure they are
    # persisted. We are specifically running the following commands after the
    # iptables rules to ensure the persisted file does not contain any
    # ephemeral neutron rules. Neutron assumes the iptables rules are not
    # persisted so it may cause an issue if the rule is loaded on boot
    # (or via iptables restart). If an operator needs to reload iptables
    # for any reason, they may need to manually reload the appropriate
    # neutron agent to restore these iptables rules.
    # https://bugzilla.redhat.com/show_bug.cgi?id=1541528
    exec { 'nonpersistent_v4_rules_cleanup':
      command => '/bin/sed -i /neutron-/d /etc/sysconfig/iptables',
      onlyif  => '/bin/test -f /etc/sysconfig/iptables && /bin/grep -q neutron- /etc/sysconfig/iptables',
    }
    exec { 'nonpersistent_v6_rules_cleanup':
      command => '/bin/sed -i /neutron-/d /etc/sysconfig/ip6tables',
      onlyif  => '/bin/test -f /etc/sysconfig/ip6tables && /bin/grep -q neutron- /etc/sysconfig/ip6tables',
    }

    # Do not persist ephemeral firewall rules mananged by ironic-inspector
    # pxe_filter 'iptables' driver.
    # https://bugs.launchpad.net/tripleo/+bug/1765700
    # https://storyboard.openstack.org/#!/story/2001890
    exec { 'nonpersistent_ironic_inspector_pxe_filter_v4_rules_cleanup':
      command => '/bin/sed -i "/-m comment --comment.*ironic-inspector/p;/ironic-inspector/d" /etc/sysconfig/iptables',
      onlyif  => [
          '/bin/test -f /etc/sysconfig/iptables',
          '/bin/grep -v "\-m comment \--comment" /etc/sysconfig/iptables | /bin/grep -q ironic-inspector'
      ]
    }
    exec { 'nonpersistent_ironic_inspector_pxe_filter_v6_rules_cleanup':
      command => '/bin/sed -i "/-m comment --comment.*ironic-inspector/p;/ironic-inspector/d" /etc/sysconfig/ip6tables',
      onlyif  => [
          '/bin/test -f /etc/sysconfig/ip6tables',
          '/bin/grep -v "\-m comment \--comment" /etc/sysconfig/ip6tables | /bin/grep -q ironic-inspector'
      ]
    }

    Firewall<| |> -> Exec['nonpersistent_v4_rules_cleanup']
    Firewall<| |> -> Exec['nonpersistent_v6_rules_cleanup']
    Firewall<| |> -> Exec['nonpersistent_ironic_inspector_pxe_filter_v4_rules_cleanup']
    Firewall<| |> -> Exec['nonpersistent_ironic_inspector_pxe_filter_v6_rules_cleanup']
  }
}
