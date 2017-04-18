#
# Copyright (C) 2016 Red Hat, Inc.
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

require 'spec_helper'

describe 'tripleo::profile::base::ceilometer' do
  shared_examples_for 'tripleo::profile::base::ceilometer' do
    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer')
        is_expected.to_not contain_class('ceilometer')
        is_expected.to_not contain_class('ceilometer::config')
      end
    end

    context 'with step 3' do
      let(:params) { {
        :step           => 3,
        :oslomsg_rpc_hosts => [ '127.0.0.1' ],
        :oslomsg_rpc_username => 'ceilometer',
        :oslomsg_rpc_password => 'foo',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceilometer').with(
          :default_transport_url => 'rabbit://ceilometer:foo@127.0.0.1:5672/?ssl=0'
        )
        is_expected.to contain_class('ceilometer::config')
      end
    end

    context 'with step 5 with bootstrap node' do
      let(:params) { {
        :bootstrap_node => 'node.example.com',
        :step             => 5,
        :oslomsg_rpc_hosts => [ '127.0.0.1' ],
        :oslomsg_rpc_username => 'ceilometer',
        :oslomsg_rpc_password => 'foo',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_exec('ceilometer-db-upgrade')
      end
    end

    context 'with step 5 without bootstrap node' do
      let(:params) { {
        :bootstrap_node => 'somethingelse.example.com',
        :step             => 5,
      } }

      it 'should trigger complete configuration' do
        is_expected.to_not contain_exec('ceilometer-db-upgrade')
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ceilometer'
    end
  end
end
