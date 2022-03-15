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

describe 'tripleo::profile::base::cinder::authtoken' do
  shared_examples_for 'tripleo::profile::base::cinder::authtoken' do
    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::cinder::authtoken')
        is_expected.to_not contain_class('cinder::keystone::authtoken')
      }
    end

    context 'with step 3' do
      let(:params) { {
        :step            => 3,
        :memcached_hosts => '127.0.0.1',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::cinder::authtoken')
        is_expected.to contain_class('cinder::keystone::authtoken').with(
          :memcached_servers => ['127.0.0.1:11211']
        )
      }
    end

    context 'with step 3 with ipv6' do
      let(:params) { {
        :step            => 3,
        :memcached_hosts => '::1',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::cinder::authtoken')
        is_expected.to contain_class('cinder::keystone::authtoken').with(
          :memcached_servers => ['inet6:[::1]:11211']
        )
      }
    end

    context 'with step 3 with the ipv6 parameter' do
      let(:params) { {
        :step            => 3,
        :memcached_hosts => 'node.example.com',
        :memcached_ipv6  => true,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::cinder::authtoken')
        is_expected.to contain_class('cinder::keystone::authtoken').with(
          :memcached_servers => ['inet6:[node.example.com]:11211']
        )
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::cinder::authtoken'
    end
  end
end
