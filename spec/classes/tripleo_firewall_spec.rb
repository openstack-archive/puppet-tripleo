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
# Unit tests for tripleo
#

require 'spec_helper'

describe 'tripleo::firewall' do

  let :params do
    { }
  end

  shared_examples_for 'tripleo::firewall' do

    context 'with firewall enabled' do
      before :each do
        params.merge!(
          :manage_firewall => true,
        )
      end

      it 'configure basic pre firewall rules' do
        is_expected.to contain_firewall('000 accept related established rules ipv4').with(
          :proto  => 'all',
          :state  => ['RELATED', 'ESTABLISHED'],
          :action => 'accept',
        )
        is_expected.to contain_firewall('000 accept related established rules ipv6').with(
          :proto    => 'all',
          :state    => ['RELATED', 'ESTABLISHED'],
          :action   => 'accept',
          :provider => 'ip6tables',
        )
        is_expected.to contain_firewall('001 accept all icmp ipv4').with(
          :proto  => 'icmp',
          :action => 'accept',
          :state  => ['NEW'],
        )
        is_expected.to contain_firewall('001 accept all icmp ipv6').with(
          :proto    => 'ipv6-icmp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'ip6tables',
        )
        is_expected.to contain_firewall('002 accept all to lo interface ipv4').with(
          :proto   => 'all',
          :iniface => 'lo',
          :action  => 'accept',
          :state   => ['NEW'],
        )
        is_expected.to contain_firewall('002 accept all to lo interface ipv6').with(
          :proto    => 'all',
          :iniface  => 'lo',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'ip6tables',
        )
      end

      it 'configure basic post firewall rules' do
        is_expected.to contain_firewall('999 drop all ipv4').with(
          :proto  => 'all',
          :action => 'drop',
        )
        is_expected.to contain_firewall('999 drop all ipv6').with(
          :proto    => 'all',
          :action   => 'drop',
          :provider => 'ip6tables',
        )
      end
    end

    context 'with custom firewall rules' do
      before :each do
        params.merge!(
          :manage_firewall     => true,
          :firewall_rules => {
            '300 add custom application 1' => {'port' => '999', 'proto' => 'udp', 'action' => 'accept'},
            '301 add custom application 2' => {'port' => '8081', 'proto' => 'tcp', 'action' => 'accept'},
            '302 fwd custom cidr 1'        => {'port' => 'all', 'chain' => 'FORWARD', 'destination' => '192.0.2.0/24'},
            '303 add custom application 3' => {'dport' => '8081', 'proto' => 'tcp', 'action' => 'accept'},
            '304 add custom application 4' => {'sport' => '1000', 'proto' => 'tcp', 'action' => 'accept'},
            '305 add gre rule'             => {'proto' => 'gre'},
            '306 add custom cidr 2'        => {'port' => 'all', 'destination' => '::1/24'},
            '307 add custom nat rule'      => {'table' => 'nat', 'source' => '192.168.0.0/24', 'destination' => '192.168.0.0/24', 'jump' => 'RETURN'},
            '308 add custom INPUT v4'      => {'ipversion' => 'ipv4', 'port' => '67', 'proto' => 'udp', 'chain' => 'INPUT', 'action' => 'accept'},
            '309 add custom INPUT v6'      => {'ipversion' => 'ipv6', 'port' => '546', 'proto' => 'udp', 'chain' => 'INPUT', 'action' => 'accept'},
          }
        )
      end
      it 'configure custom firewall rules' do
        is_expected.to contain_firewall('300 add custom application 1 ipv4').with(
          :port     => '999',
          :proto    => 'udp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'iptables',
        )
        is_expected.to contain_firewall('301 add custom application 2 ipv4').with(
          :port     => '8081',
          :proto    => 'tcp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'iptables',
        )
        is_expected.to contain_firewall('302 fwd custom cidr 1 ipv4').with(
          :chain       => 'FORWARD',
          :proto       => 'tcp',
          :destination => '192.0.2.0/24',
          :provider    => 'iptables',
        )
        is_expected.to_not contain_firewall('302 fwd custom cidr 1 ipv6')
        is_expected.to contain_firewall('303 add custom application 3 ipv4').with(
          :dport    => '8081',
          :proto    => 'tcp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'iptables',
        )
        is_expected.to contain_firewall('304 add custom application 4 ipv4').with(
          :sport    => '1000',
          :proto    => 'tcp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'iptables',
        )
        is_expected.to contain_firewall('304 add custom application 4 ipv6').with(
          :sport    => '1000',
          :proto    => 'tcp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'ip6tables',
        )
        is_expected.to contain_firewall('305 add gre rule ipv4').without(:state)
        is_expected.to contain_firewall('306 add custom cidr 2 ipv6').with(
          :proto       => 'tcp',
          :destination => '::1/24',
          :action      => 'accept',
          :provider    => 'ip6tables',
        )
        is_expected.to contain_firewall('307 add custom nat rule ipv4').with(
          :destination => '192.168.0.0/24',
          :source      => '192.168.0.0/24',
          :jump        => 'RETURN',
          :table       => 'nat',
          :provider    => 'iptables',
        )
        is_expected.to contain_firewall('308 add custom INPUT v4 ipv4').with(
          :chain    => 'INPUT',
          :port     => '67',
          :proto    => 'udp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'iptables',
        )
        is_expected.to contain_firewall('309 add custom INPUT v6 ipv6').with(
          :chain    => 'INPUT',
          :port     => '546',
          :proto    => 'udp',
          :action   => 'accept',
          :state    => ['NEW'],
          :provider => 'ip6tables',
        )
      end
    end

    context 'with TCP rule without port or dport or sport specified' do
      before :each do
        params.merge!(
          :manage_firewall => true,
          :firewall_rules  => {
            '500 wrong tcp rule' => {'proto' => 'tcp', 'action' => 'accept'},
          }
        )
      end
      it_raises 'a Puppet::Error', /500 wrong tcp rule firewall rule cannot be created. TCP or UDP rules for INPUT or OUTPUT need port or sport or dport./
    end

    context 'with firewall chain' do
      before :each do
        params.merge!(
          :manage_firewall => true,
          :firewall_chains => {
            'FORWARD:filter:IPv4' => {
              'ensure' => 'present',
              'policy' => 'accept',
              'purge'  => false
            }
          })
      end

      it {
        is_expected.to contain_firewallchain('FORWARD:filter:IPv4').with(
          'ensure' => 'present',
          'policy' => 'accept',
          'purge'  => false)
      }

    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::firewall'
    end
  end
end
