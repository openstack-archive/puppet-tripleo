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

describe 'tripleo::profile::base::ceilometer::agent::polling' do
  shared_examples_for 'tripleo::profile::base::ceilometer::agent::polling' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      "class { 'tripleo::profile::base::ceilometer': step => #{params[:step]}, oslomsg_rpc_hosts => ['localhost.localdomain'] }"
    end

    context 'with step less than 4' do
      let(:params) { { :step => 3 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer::agent::polling')
        is_expected.to_not contain_class('ceilometer::agent::service_credentials')
        is_expected.to_not contain_class('ceilometer::agent::polling')
      end
    end

    context 'with step 4 on polling agent' do
      let(:params) { {
        :step                      => 4,
        :ceilometer_redis_password => 'password',
        :redis_vip                 => '127.0.0.1',
        :central_namespace         => true
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceilometer::agent::service_credentials')
        is_expected.to contain_class('ceilometer::agent::polling').with(
          :central_namespace => true,
          :compute_namespace => false,
          :ipmi_namespace    => false,
          :coordination_url  => 'redis://:password@127.0.0.1:6379/',
        )
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ceilometer::agent::polling'
    end
  end
end
