#
# Copyright (C) 2022 Red Hat, Inc.
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

describe 'tripleo::profile::base::designate::coordination' do
  shared_examples_for 'tripleo::profile::base::designate::coordination' do
    context 'with step less than 4' do
      let(:params) { {
        :step                     => 3,
        :designate_redis_password => 'a_redis_password',
        :redis_vip                => '192.0.2.1',
      } }
      it {
        is_expected.to_not contain_class('designate::coordination')
      }
    end

    context 'with step 4 and without a redis vip' do
      let(:params) { {
        :step                     => 4,
        :designate_redis_password => 'a_redis_password',
        # NOTE(tkajinam): Currently redis_vip is defined in test hieradata.
        #                 Here we override the parameter to test the logic used
        #                 when redis_vip is not set.
        :redis_vip                => false,
      } }
      it {
        is_expected.to_not contain_class('designate::coordination')
      }
    end

    context 'with step 4 and a typical configuration no tls' do
      let(:params) { {
        :step                     => 4,
        :designate_redis_password => 'a_redis_password',
        :redis_vip                => '192.0.2.1',
      } }
      it {
        is_expected.to contain_class('designate::coordination').with(
          :backend_url => 'redis://:a_redis_password@192.0.2.1:6379/'
        )
      }
    end

    context 'with 4 and a typical configuration tls enabled' do
      let(:params) { {
        :step                     => 4,
        :designate_redis_password => 'a_redis_password',
        :redis_vip                => '192.0.2.1',
        :enable_internal_tls      => true
      } }
      it {
        is_expected.to contain_class('designate::coordination').with(
          :backend_url => 'redis://:a_redis_password@192.0.2.1:6379/?ssl=true'
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::designate::coordination'
    end
  end
end
