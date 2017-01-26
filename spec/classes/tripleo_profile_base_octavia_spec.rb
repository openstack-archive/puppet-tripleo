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

describe 'tripleo::profile::base::octavia' do

  let :params do
    { :oslomsg_rpc_hosts => ['some.server.com'],
      :step         => 5
    }
  end

  shared_examples_for 'tripleo::profile::base::octavia' do

    context 'with step less than 3' do
      before do
        params.merge!({ :step => 2 })
      end

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia')
        is_expected.to_not contain_class('octavia::config')
      end
    end

    context 'with step 3' do
      before do
        params.merge!({ :step => 3 })
      end

      it 'should provide basic initialization' do
        is_expected.to contain_class('octavia').with(
          :default_transport_url => 'rabbit://guest:password@some.server.com:5672/?ssl=0'
        )
        is_expected.to contain_class('octavia::config')
      end
    end

    context 'with multiple hosts' do
      before do
        params.merge!({ :oslomsg_rpc_hosts => ['some.server.com', 'someother.server.com'] })
      end

      it 'should construct a multihost URL' do
        is_expected.to contain_class('octavia').with(
          :default_transport_url => 'rabbit://guest:password@some.server.com:5672,guest:password@someother.server.com:5672/?ssl=0'
        )
      end
    end

    context 'with username provided' do
      before do
        params.merge!({ :oslomsg_rpc_username => 'bunny' })
      end

      it 'should construct URL with username' do
        is_expected.to contain_class('octavia').with(
          :default_transport_url => 'rabbit://bunny:password@some.server.com:5672/?ssl=0'
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
        is_expected.to contain_class('octavia').with(
          :default_transport_url => 'rabbit://bunny:carrot@some.server.com:5672/?ssl=0'
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
        is_expected.to contain_class('octavia').with(
          :default_transport_url => 'rabbit://bunny:carrot@some.server.com:5672,bunny:carrot@someother.server.com:5672/?ssl=0'
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end
      it_behaves_like 'tripleo::profile::base::octavia'
    end
  end
end
