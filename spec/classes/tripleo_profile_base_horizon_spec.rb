#
# Copyright (C) 2017 Red Hat, Inc.
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

describe 'tripleo::profile::base::horizon' do
  shared_examples_for 'tripleo::profile::base::horizon' do
    let(:pre_condition) do
      "class { 'tripleo::profile::base::aodh': step => #{params[:step]}, oslomsg_rpc_hosts => ['localhost.localdomain'] }"
    end

    context 'with step less than 3' do
      let(:params) { { :step => 2 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::horizon')
        is_expected.to_not contain_class('horizon')
        is_expected.to_not contain_class('horizon::dashboards::heat')
      end
    end

    context 'with step 3 and not bootstrap' do
      let(:params) { {
        :step => 3,
      } }

      it 'should not configure anything' do
        is_expected.to_not contain_class('horizon')
        is_expected.to_not contain_class('horizon::dashboards::heat')
        is_expected.to_not contain_class('apache::mod::remoteip')
        is_expected.to_not contain_class('apache::mod::status')
      end
    end

    context 'with step 3 and bootstrap' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com'
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('horizon')
        is_expected.to_not contain_class('horizon::dashboards::heat')
        is_expected.to contain_class('apache::mod::remoteip')
        is_expected.to contain_class('apache::mod::status')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com'
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('horizon')
        is_expected.to_not contain_class('horizon::dashboards::heat')
        is_expected.to contain_class('apache::mod::remoteip')
        is_expected.to contain_class('apache::mod::status')
      end
    end

    context 'with step 4 and heat enabled' do
      let(:params) { {
        :step             => 4,
        :bootstrap_node   => 'node.example.com',
        :heat_api_enabled => true,
      } }

      it 'should trigger complete configuration with heat dashboard' do
        is_expected.to contain_class('horizon')
        is_expected.to contain_class('horizon::dashboards::heat')
        is_expected.to contain_class('apache::mod::remoteip')
        is_expected.to contain_class('apache::mod::status')
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::horizon'
    end
  end
end
