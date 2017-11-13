#
# Copyright (C) 2017 Camptocamp SA.
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

describe 'tripleo::profile::base::apache' do
  shared_examples_for 'tripleo::profile::base::apache' do

    context 'with default params' do
      it 'should trigger complete configuration' do
        is_expected.to contain_class('apache::mod::status')
        is_expected.to contain_class('apache::mod::ssl')
        is_expected.to_not contain_apache__listen('127.0.0.1:80')
      end
    end

    context 'Activate listener' do
      let(:params) { {
        :enable_status_listener => true,
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('apache::mod::status')
        is_expected.to contain_class('apache::mod::ssl')
        is_expected.to contain_apache__listen('127.0.0.1:80')
      end
    end

    context 'Change listener' do
      let(:params) {{
        :enable_status_listener => true,
        :status_listener        => '10.10.0.10:80',
      }}
      it 'should trigger complete configuration' do
        is_expected.to contain_class('apache::mod::status')
        is_expected.to contain_class('apache::mod::ssl')
        is_expected.to contain_apache__listen('10.10.0.10:80')
      end
    end


    context 'Provide wrong value for ensure_status_listener' do
      let(:params) {{
        :enable_status_listener => 'fooo',
      }}
      it { is_expected.to compile.and_raise_error(/expects a Boolean value/) }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::apache'
    end
  end
end
