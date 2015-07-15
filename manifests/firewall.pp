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
# [*firewall_rules*]
#   (optional) Allow to add custom firewall rules
#   Should be an hash.
#   Default to {}
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
  $manage_firewall      = false,
  $firewall_rules       = {},
  $purge_firewall_rules = false,
  $firewall_pre_extras  = {},
  $firewall_post_extras = {},
) {

  include ::stdlib

  if $manage_firewall {

    # Only purges IPv4 rules
    if $purge_firewall_rules {
      resources { 'firewall':
        purge => true
      }
    }

    # anyone can add your own rules
    # example with Hiera:
    #
    # tripleo::firewall::rules:
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
      'stage'             => 'setup',
    })

    ensure_resource('class', 'tripleo::firewall::post', {
      'stage'             => 'runtime',
      'firewall_settings' => $firewall_post_extras,
    })
  }

}
