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
# Unit tests for the zookeeper service

require 'spec_helper'

describe 'tripleo::cluster::zookeeper' do

  shared_examples_for 'tripleo::cluster::zookeeper' do
    let :params do
      {
        :zookeeper_server_ips => ['23.43.2.34', '23.43.2.35', '24.43.2.36'],
        :zookeeper_hostnames  => ['host1.midonet', 'host2.midonet', 'host3.midonet']
      }
    end

    context 'on host1' do
      before :each do
        facts.merge!({ :hostname => 'host1.midonet'})
        params.merge!({ :zookeeper_client_ip => '23.43.2.34' })
      end

      it 'should call zookeeper using id==1' do
        is_expected.to contain_class('zookeeper').with(
          :servers   => ['23.43.2.34', '23.43.2.35', '24.43.2.36'],
          :client_ip => '23.43.2.34',
          :id        => 1
        )
      end
    end

    context 'on host2' do
      before :each do
        facts.merge!({ :hostname => 'host2.midonet'})
        params.merge!({ :zookeeper_client_ip => '23.43.2.35' })
      end

      it 'should call zookeeper using id==1' do
        is_expected.to contain_class('zookeeper').with(
          :servers   => ['23.43.2.34', '23.43.2.35', '24.43.2.36'],
          :client_ip => '23.43.2.35',
          :id        => 2
        )
      end
    end

    context 'on host3' do
      before :each do
        facts.merge!({ :hostname => 'host3.midonet'})
        params.merge!({ :zookeeper_client_ip => '23.43.2.36' })
      end

      it 'should call zookeeper using id==1' do
        is_expected.to contain_class('zookeeper').with(
          :servers   => ['23.43.2.34', '23.43.2.35', '24.43.2.36'],
          :client_ip => '23.43.2.36',
          :id        => 3
        )
      end

    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::cluster::zookeeper'
    end
  end
end
