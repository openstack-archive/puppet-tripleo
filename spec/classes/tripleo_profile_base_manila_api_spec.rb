#
# Copyright (C) 2019 Red Hat, Inc.
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

describe 'tripleo::profile::base::manila::api' do
  shared_examples_for 'tripleo::profile::base::manila::api' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::manila':
        step => #{params[:step]},
        oslomsg_rpc_hosts    => [ 'localhost' ],
        oslomsg_rpc_username => 'manila',
        oslomsg_rpc_password => 'foo'
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to contain_class('tripleo::profile::base::manila::authtoken')
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('manila::api')
        is_expected.to_not contain_class('manila::wsgi::apache')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step                    => 3,
        :bootstrap_node          => 'node.example.com',
        :backend_generic_enabled => true
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to contain_class('tripleo::profile::base::manila::authtoken')
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('manila::api').with(
          :enabled_share_protocols => 'NFS,CIFS'
        )
        is_expected.to contain_class('manila::wsgi::apache')
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to contain_class('tripleo::profile::base::manila::authtoken')
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('manila::api')
        is_expected.to_not contain_class('manila::wsgi::apache')
      }
    end

    context 'with step 4' do
      let(:params) { {
        :step                    => 4,
        :bootstrap_node          => 'other.example.com',
        :backend_generic_enabled => true
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to contain_class('tripleo::profile::base::manila::authtoken')
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('manila::api').with(
          :enabled_share_protocols => 'NFS,CIFS'
        )
        is_expected.to contain_class('manila::wsgi::apache')
        is_expected.to contain_class('tripleo::profile::base::manila::api')
      }
    end

    context 'with cephfs enabled' do
      let(:params) { {
        :step                    => 4,
        :bootstrap_node          => 'node.example.com',
        :backend_generic_enabled => true,
        :backend_cephfs_enabled  => true
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to contain_class('tripleo::profile::base::manila::authtoken')
        is_expected.to contain_class('tripleo::profile::base::manila::api')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('manila::api').with(
          :enabled_share_protocols => 'NFS,CIFS,CEPHFS'
        )
        is_expected.to contain_class('manila::wsgi::apache')
        is_expected.to contain_class('tripleo::profile::base::manila::api')
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::manila::api'
    end
  end
end
