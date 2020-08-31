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

describe 'tripleo::profile::base::gnocchi' do

  before :each do
    facts.merge!({ :step => params[:step] })
  end

  shared_examples_for 'tripleo::profile::base::gnocchi' do
    context 'with step less than 3' do
      let(:params) { {
        :step => 2,
      } }

      it {
        is_expected.to_not contain_class('gnocchi')
        is_expected.to_not contain_class('gnocchi::db')
        is_expected.to_not contain_class('gnocchi::config')
        is_expected.to_not contain_class('gnocchi::cors')
        is_expected.to_not contain_class('gnocchi::client')
        is_expected.to_not contain_class('gnocchi::logging')
      }
    end

    context 'with step 3 on bootstrap' do
      let(:params) { {
        :step                   => 3,
        :bootstrap_node         => 'node.example.com',
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip              => '127.0.0.1',
      } }

      it {
        is_expected.to contain_class('gnocchi').with(
          :coordination_url => 'redis://:gnocchi@127.0.0.1:6379/'
        )
        is_expected.to contain_class('gnocchi::db')
        is_expected.to contain_class('gnocchi::config')
        is_expected.to contain_class('gnocchi::cors')
        is_expected.to contain_class('gnocchi::client')
        is_expected.to contain_class('gnocchi::logging')
      }
    end

    context 'with step 3 not on bootstrap' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to_not contain_class('gnocchi')
        is_expected.to_not contain_class('gnocchi::db')
        is_expected.to_not contain_class('gnocchi::config')
        is_expected.to_not contain_class('gnocchi::cors')
        is_expected.to_not contain_class('gnocchi::client')
        is_expected.to_not contain_class('gnocchi::logging')
      }
    end

    context 'with step 4' do
      let(:params) { {
        :step                   => 4,
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip              => '127.0.0.1',
      } }

      it {
        is_expected.to contain_class('gnocchi').with(
          :coordination_url => 'redis://:gnocchi@127.0.0.1:6379/'
        )
        is_expected.to contain_class('gnocchi::db')
        is_expected.to contain_class('gnocchi::config')
        is_expected.to contain_class('gnocchi::cors')
        is_expected.to contain_class('gnocchi::client')
        is_expected.to contain_class('gnocchi::logging')
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::gnocchi'
    end
  end
end

