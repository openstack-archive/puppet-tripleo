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

describe 'tripleo::profile::base::aodh' do
  shared_examples_for 'tripleo::profile::base::aodh' do
    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::aodh')
        is_expected.to_not contain_class('aodh')
        is_expected.to_not contain_class('aodh::auth')
        is_expected.to_not contain_class('aodh::config')
        is_expected.to_not contain_class('aodh::client')
        is_expected.to_not contain_class('aodh::db::sync')
      end
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com',
        :rabbit_hosts   => ['127.0.0.1', '127.0.0.2']
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('aodh').with(
          :rabbit_hosts => params[:rabbit_hosts]
        )
        is_expected.to contain_class('aodh::auth')
        is_expected.to contain_class('aodh::config')
        is_expected.to contain_class('aodh::client')
        is_expected.to contain_class('aodh::db::sync')
      end
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step => 3,
        :bootstrap_node => 'soemthingelse.example.com'
      } }

      it 'should not trigger any configuration' do
        is_expected.to_not contain_class('aodh')
        is_expected.to_not contain_class('aodh::auth')
        is_expected.to_not contain_class('aodh::config')
        is_expected.to_not contain_class('aodh::client')
        is_expected.to_not contain_class('aodh::db::sync')
      end
    end

    context 'with step 4 on other node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'somethingelse.example.com',
        :rabbit_hosts   => ['127.0.0.1', '127.0.0.2']
      } }

      it 'should trigger aodh configuration without mysql grant' do
        is_expected.to contain_class('aodh').with(
          :rabbit_hosts => params[:rabbit_hosts]
        )
        is_expected.to contain_class('aodh::auth')
        is_expected.to contain_class('aodh::config')
        is_expected.to contain_class('aodh::client')
        is_expected.to contain_class('aodh::db::sync')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::aodh'
    end
  end
end
