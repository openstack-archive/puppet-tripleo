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

describe 'tripleo::profile::base::cinder::api' do
  shared_examples_for 'tripleo::profile::base::cinder::api' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      "class { '::tripleo::profile::base::cinder': step => #{params[:step]}, oslomsg_rpc_hosts => ['127.0.0.1'] }"
    end

    context 'with step less than 3' do
      let(:params) { { :step => 1 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::api')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_class('cinder::api')
        is_expected.to_not contain_class('cinder::ceilometer')
      end
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('cinder::api').with(
          :sync_db        => true,
          # Verify legacy key manager is enabled when none is set in hiera.
          :keymgr_backend => 'cinder.keymgr.conf_key_mgr.ConfKeyManager',
        )
        is_expected.to contain_class('cinder::ceilometer')
      end
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it 'should not trigger any configuration' do
        is_expected.to_not contain_class('cinder::api')
        is_expected.to_not contain_class('cinder::ceilometer')
      end
    end

    context 'with step 4 on bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'node.example.com',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('cinder::api').with(
          :sync_db        => true,
          :keymgr_backend => 'castellan.key_manager.barbican_key_manager.BarbicanKeyManager',
        )
        is_expected.to contain_class('cinder::ceilometer')
        is_expected.to contain_cinder__type('tripleo')
      end
    end

    context 'with step 4 not on bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com',
      } }

      it 'should trigger complete configuration but with no db sync or default volume type' do
        is_expected.to contain_class('cinder::api').with(
          :sync_db        => false,
          :keymgr_backend => 'castellan.key_manager.barbican_key_manager.BarbicanKeyManager',
        )
        is_expected.to contain_class('cinder::ceilometer')
        is_expected.to_not contain_cinder__type('tripleo')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::cinder::api'
    end
  end
end
