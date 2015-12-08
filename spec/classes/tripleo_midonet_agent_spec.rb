#
# Copyright (C) 2015 Midokura SARL
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
# Unit tests for the midonet agent

require 'spec_helper'

describe 'tripleo::network::midonet::agent' do

  let :facts do
    {
      :hostname                  => 'host2.midonet',
      :osfamily                  => 'RedHat',
      :operatingsystem           => 'CentOS',
      :operatingsystemrelease    => '7.1',
      :operatingsystemmajrelease => 7,
    }
  end

  shared_examples_for 'midonet agent test' do

    let :params do
      {
        :zookeeper_servers => ['192.168.2.2', '192.168.2.3'],
        :cassandra_seeds   => ['192.168.2.2', '192.168.2.3']
      }
    end

    it 'should stop openvswitch' do
      is_expected.to contain_service('openvswitch').with(
        :ensure => 'stopped',
        :enable => false
      )
    end

    it 'should run the agent with a list of maps' do
      is_expected.to contain_class('midonet::midonet_agent').with(
        :zk_servers => [{'ip'   => '192.168.2.2',
                         'port' => 2181},
                        {'ip'   => '192.168.2.3',
                         'port' => 2181}],
        :cassandra_seeds   => ['192.168.2.2','192.168.2.3']
      )
    end
  end

  it_configures 'midonet agent test'


end
