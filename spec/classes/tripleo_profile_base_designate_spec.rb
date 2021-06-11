#
# Copyright (C) 2020 Red Hat, Inc.
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

describe 'tripleo::profile::base::designate' do
  shared_examples_for 'tripleo::profile::base::designate' do

    context 'with step less than 3' do
      let(:params) { {
        :step                 => 1,
        :oslomsg_rpc_hosts    => [ 'localhost' ],
        :oslomsg_rpc_password => 'foo'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::designate')
        is_expected.to_not contain_class('designate')
        is_expected.to_not contain_class('designate::config')
        is_expected.to_not contain_class('designate::logging')
      }
    end

    context 'with step 3' do
      let(:params) { {
        :step                 => 3,
        :oslomsg_rpc_hosts    => [ 'localhost' ],
        :oslomsg_rpc_username => 'designate',
        :oslomsg_rpc_password => 'foo',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::designate')
        is_expected.to contain_class('designate').with(
          :default_transport_url => 'rabbit://designate:foo@localhost:5672/?ssl=0'
        )
        is_expected.to contain_class('designate::config')
        is_expected.to contain_class('designate::logging')
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::designate'
    end
  end
end
