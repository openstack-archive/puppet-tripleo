#
# Copyright (C) 2020 Red Hat Inc.
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

require 'spec_helper'

describe 'tripleo::profile::base::swift' do

  shared_examples_for 'tripleo::profile::base::swift' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let :pre_condition do
      "class { 'swift':
         swift_hash_path_prefix => 'foo',
       }
       include memcached
      "
    end

    context 'with ipv4 memcache servers' do
      let(:params) { {
        :step             => 4,
        :memcache_servers => ['192.168.0.1', '192.168.0.2'],
      } }

      it 'configure cache with ipv4 ips' do
        is_expected.to contain_class('swift::objectexpirer').with({
          :pipeline         => ['catch_errors', 'cache', 'proxy-server'],
          :memcache_servers => ['192.168.0.1:11211', '192.168.0.2:11211']
        })
      end
    end

    context 'with ipv6 memcache servers' do
      let(:params) { {
          :step             => 4,
          :memcache_servers => ['::1', '::2'],
      } }

      it 'configure cache with ipv6 ips' do
        is_expected.to contain_class('swift::objectexpirer').with({
          :pipeline         => ['catch_errors', 'cache', 'proxy-server'],
          :memcache_servers => ['[::1]:11211', '[::2]:11211']
        })
      end
    end

    context 'with ipv4, ipv6 and fqdn memcache servers' do
      let(:params) { {
          :step             => 4,
          :memcache_servers => ['192.168.0.1', '::2', 'myserver.com'],
      } }

      it 'configure cache with ips and fqdn' do
        is_expected.to contain_class('swift::objectexpirer').with({
          :pipeline         => ['catch_errors', 'cache', 'proxy-server'],
          :memcache_servers => ['192.168.0.1:11211', '[::2]:11211', 'myserver.com:11211']
        })
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::swift'
    end
  end
end
