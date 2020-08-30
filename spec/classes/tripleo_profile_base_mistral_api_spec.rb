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

describe 'tripleo::profile::base::mistral::api' do
  shared_examples_for 'tripleo::profile::base::mistral::api' do
    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::mistral':
        step => #{params[:step]},
      }
      class { 'tripleo::profile::base::mistral::authtoken':
        step => #{params[:step]},
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::mistral::api')
        is_expected.to contain_class('tripleo::profile::base::mistral')
        is_expected.to contain_class('tripleo::profile::base::mistral::authtoken')
        is_expected.to_not contain_class('mistral::api')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('mistral::wsgi::apache')
      end
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::mistral::api')
        is_expected.to contain_class('tripleo::profile::base::mistral')
        is_expected.to contain_class('tripleo::profile::base::mistral::authtoken')
        is_expected.to contain_class('mistral::api')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('mistral::wsgi::apache')
      end
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com'
      } }

      it 'should not trigger any configuration' do
        is_expected.to contain_class('tripleo::profile::base::mistral::api')
        is_expected.to contain_class('tripleo::profile::base::mistral')
        is_expected.to contain_class('tripleo::profile::base::mistral::authtoken')
        is_expected.to_not contain_class('mistral::api')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('mistral::wsgi::apache')
      end
    end

    context 'with step 4 on other node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::mistral::api')
        is_expected.to contain_class('tripleo::profile::base::mistral')
        is_expected.to contain_class('tripleo::profile::base::mistral::authtoken')
        is_expected.to contain_class('mistral::api')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('mistral::wsgi::apache')
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::mistral::api'
    end
  end
end
