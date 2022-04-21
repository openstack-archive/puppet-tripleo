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

describe 'tripleo::profile::base::aodh::evaluator' do
  shared_examples_for 'tripleo::profile::base::aodh::evaluator' do
    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::aodh':
        step              => #{params[:step]},
        oslomsg_rpc_hosts => ['localhost.localdomain']
      }
eos
    end

    context 'with step less than 4' do
      let(:params) { {
        :step                => 3,
        :aodh_redis_password => 'password',
        :redis_vip           => '127.0.0.1',
      } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::aodh::evaluator')
        is_expected.to contain_class('tripleo::profile::base::aodh')
        is_expected.to_not contain_class('aodh::coordination')
        is_expected.to_not contain_class('aodh::evaluator')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :step                => 4,
        :aodh_redis_password => 'password',
        :redis_vip           => '127.0.0.1',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('aodh::coordination').with(
          :backend_url => 'redis://:password@127.0.0.1:6379/'
        )
        is_expected.to contain_class('aodh::evaluator')
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::aodh::evaluator'
    end
  end
end
