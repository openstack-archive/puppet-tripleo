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

describe 'tripleo::profile::base::novajoin' do

  shared_examples_for 'tripleo::profile::base::novajoin' do

    let :pre_condition do
      <<-eos
      include nova
      class { 'tripleo::profile::base::novajoin::authtoken':
        step => #{params[:step]},
      }
eos
    end

    let :params do
      { :oslomsg_rpc_hosts    => ['some.server.com'],
        :oslomsg_rpc_password => 'somepassword',
        :service_password     => 'passw0rd',
        :step                 => 5
      }
    end

    context 'with step less than 3' do
      before do
        params.merge!({ :step => 2 })
      end

      it 'should not do anything' do
        is_expected.to contain_class('tripleo::profile::base::novajoin::authtoken')
        is_expected.to_not contain_class('nova::metadata::novajoin::api')
      end
    end

    context 'with step 3' do
      before do
        params.merge!({ :step => 3 })
      end

      it 'should provide basic initialization' do
        is_expected.to contain_class('tripleo::profile::base::novajoin::authtoken')
        is_expected.to contain_class('nova::metadata::novajoin::api').with(
          :transport_url => 'rabbit://guest:somepassword@some.server.com:5672/?ssl=0'
        )
      end
    end

    context 'with multiple hosts' do
      before do
        params.merge!({ :oslomsg_rpc_hosts => ['some.server.com', 'someother.server.com'] })
      end

      it 'should construct a multihost URL' do
        is_expected.to contain_class('nova::metadata::novajoin::api').with(
          :transport_url => 'rabbit://guest:somepassword@some.server.com:5672,guest:somepassword@someother.server.com:5672/?ssl=0'
        )
      end
    end

    context 'with username provided' do
      before do
        params.merge!({ :oslomsg_rpc_username => 'bunny' })
      end

      it 'should construct URL with username' do
        is_expected.to contain_class('nova::metadata::novajoin::api').with(
          :transport_url => 'rabbit://bunny:somepassword@some.server.com:5672/?ssl=0'
        )
      end
    end

    context 'with username and password provided' do
      before do
        params.merge!(
          { :oslomsg_rpc_username  => 'bunny',
            :oslomsg_rpc_password  => 'carrot'
          }
        )
      end

      it 'should construct URL with username and password' do
        is_expected.to contain_class('nova::metadata::novajoin::api').with(
          :transport_url => 'rabbit://bunny:carrot@some.server.com:5672/?ssl=0'
        )
      end
    end

    context 'with multiple hosts and user info provided' do
      before do
        params.merge!(
          { :oslomsg_rpc_hosts     => ['some.server.com', 'someother.server.com'],
            :oslomsg_rpc_username  => 'bunny',
            :oslomsg_rpc_password  => 'carrot'
          }
        )
      end

      it 'should distributed user info across hosts URL' do
        is_expected.to contain_class('nova::metadata::novajoin::api').with(
          :transport_url => 'rabbit://bunny:carrot@some.server.com:5672,bunny:carrot@someother.server.com:5672/?ssl=0'
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end
      it_behaves_like 'tripleo::profile::base::novajoin'
    end
  end
end
