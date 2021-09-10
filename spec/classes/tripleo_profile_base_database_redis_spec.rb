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

describe 'tripleo::profile::base::database::redis' do
  shared_examples_for 'tripleo::profile::base::database::redis' do

    context 'with step less than 2' do
      let(:params) { {
        :step => 1,
      } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::database::redis')
        is_expected.to_not contain_class('redis')
        is_expected.to_not contain_class('tripleo::redis_notification')
      end
    end

    context 'with step 2' do
      let(:params) { {
        :step => 2,
      } }

      it 'should configure redis' do
        is_expected.to contain_class('tripleo::profile::base::database::redis')
        is_expected.to contain_class('redis')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::database::redis'
    end
  end
end
