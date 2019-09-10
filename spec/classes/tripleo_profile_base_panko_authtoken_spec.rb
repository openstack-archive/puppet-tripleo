#
# Copyright (C) 2019 Red Hat, Inc.
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

describe 'tripleo::profile::base::panko::authtoken' do
  shared_examples_for 'tripleo::profile::base::panko::authtoken' do
    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::panko::authtoken')
        is_expected.to_not contain_class('panko::keystone::authtoken')
      }
    end

    context 'with step 3' do
      let(:params) { {
        :step => 3,
        :memcached_ips => '127.0.0.1',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::panko::authtoken')
        is_expected.to contain_class('panko::keystone::authtoken').with(
            :memcached_servers => ['127.0.0.1:11211'])
      }
    end

    context 'with step 3 with ipv6' do
      let(:params) { {
        :step     => 3,
        :memcached_ips => '::1',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::panko::authtoken')
        is_expected.to contain_class('panko::keystone::authtoken').with(
            :memcached_servers => ['[::1]:11211'])
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::panko::authtoken'
    end
  end
end
