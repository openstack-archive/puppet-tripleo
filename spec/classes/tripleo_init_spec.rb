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

describe 'tripleo' do

  let :params do
    { }
  end

  shared_examples_for 'tripleo node' do

    context 'with firewall enabled' do
      before :each do
        params.merge!(
          :manage_firewall => true,
        )
      end

      it 'configure basic pre firewall rules' do
        is_expected.to contain_firewall('000 accept related established rules').with(
          :proto  => 'all',
          :state  => ['RELATED', 'ESTABLISHED'],
          :action => 'accept',
        )
        is_expected.to contain_firewall('001 accept all icmp').with(
          :proto  => 'icmp',
          :action => 'accept',
          :state  => ['NEW'],
        )
        is_expected.to contain_firewall('002 accept all to lo interface').with(
          :proto   => 'all',
          :iniface => 'lo',
          :action  => 'accept',
          :state   => ['NEW'],
        )
        is_expected.to contain_firewall('003 accept ssh').with(
          :port   => '22',
          :proto  => 'tcp',
          :action => 'accept',
          :state  => ['NEW'],
        )
      end

      it 'configure basic post firewall rules' do
        is_expected.to contain_firewall('999 drop all').with(
          :proto  => 'all',
          :action => 'drop',
          :source => '0.0.0.0/0',
        )
      end
    end

    context 'with custom firewall rules' do
      before :each do
        params.merge!(
          :manage_firewall     => true,
          :firewall_rules => {
            '300 add custom application 1' => {'port' => '999', 'proto' => 'udp', 'action' => 'accept'},
            '301 add custom application 2' => {'port' => '8081', 'proto' => 'tcp', 'action' => 'accept'}
          }
        )
      end
      it 'configure custom firewall rules' do
        is_expected.to contain_firewall('300 add custom application 1').with(
          :port   => '999',
          :proto  => 'udp',
          :action => 'accept',
          :state  => ['NEW'],
        )
        is_expected.to contain_firewall('301 add custom application 2').with(
          :port   => '8081',
          :proto  => 'tcp',
          :action => 'accept',
          :state  => ['NEW'],
        )
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'tripleo node'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'tripleo node'
  end

end
