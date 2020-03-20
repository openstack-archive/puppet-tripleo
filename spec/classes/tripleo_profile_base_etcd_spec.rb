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
#
# Unit tests for tripleo
#

require 'spec_helper'

describe 'tripleo::profile::base::etcd' do

  shared_examples_for 'tripleo::profile::base::etcd' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 2' do
      let(:params) { { :step => 1 } }

      it 'should do nothing' do
        is_expected.to_not contain_class('etcd')
      end
    end

    context 'with step 2' do
      let(:params) { { :step => 2 } }

      context 'with defaults' do
        it 'should configure etcd with defaults' do
          is_expected.to contain_class('etcd').with(
            :listen_client_urls          => 'http://127.0.0.1:2379',
            :advertise_client_urls       => 'http://127.0.0.1:2379',
            :listen_peer_urls            => 'http://127.0.0.1:2380',
            :initial_advertise_peer_urls => 'http://127.0.0.1:2380',
            :initial_cluster             => [],
            :proxy                       => 'off',
            :cert_file                   => nil,
            :key_file                    => nil,
            :client_cert_auth            => false,
            :peer_cert_file              => nil,
            :peer_key_file               => nil,
            :peer_client_cert_auth       => false,
          )
        end
      end

      context 'with overrides' do
        before :each do
          params.merge!({
            :bind_ip     => '127.0.0.2',
            :client_port => '1234',
            :peer_port   => '4321',
            :nodes       => ['node3', 'node4']
          })
        end
        it 'should configure etcd with overrides' do
          is_expected.to contain_class('etcd').with(
            :listen_client_urls          => 'http://127.0.0.2:1234',
            :advertise_client_urls       => 'http://127.0.0.2:1234',
            :listen_peer_urls            => 'http://127.0.0.2:4321',
            :initial_advertise_peer_urls => 'http://127.0.0.2:4321',
            :initial_cluster             => ['node3=http://node3:4321', 'node4=http://node4:4321'],
          )
        end
      end

      context 'with TLS enabled' do
        before :each do
          params.merge!({
            :enable_internal_tls => true,
            :certificate_specs   => {
              'service_certificate' => '/path/to/etcd.cert',
              'service_key'         => '/path/to/etcd.key',
            },
          })
        end
        it 'should configure etcd with TLS' do
          is_expected.to contain_class('etcd').with(
            :listen_client_urls          => 'https://127.0.0.1:2379',
            :advertise_client_urls       => 'https://127.0.0.1:2379',
            :listen_peer_urls            => 'https://127.0.0.1:2380',
            :initial_advertise_peer_urls => 'https://127.0.0.1:2380',
            :cert_file                   => '/path/to/etcd.cert',
            :key_file                    => '/path/to/etcd.key',
            :client_cert_auth            => true,
            :peer_cert_file              => '/path/to/etcd.cert',
            :peer_key_file               => '/path/to/etcd.key',
            :peer_client_cert_auth       => true,
          )
        end
      end

      context 'with an IPv6 bind_ip' do
        before :each do
          params.merge!({
            :bind_ip     => 'fe80::1ff:fe23:4567:890a',
          })
        end
        it 'should normalize it in the URLs' do
          is_expected.to contain_class('etcd').with(
            :listen_client_urls          => 'http://[fe80::1ff:fe23:4567:890a]:2379',
            :advertise_client_urls       => 'http://[fe80::1ff:fe23:4567:890a]:2379',
            :listen_peer_urls            => 'http://[fe80::1ff:fe23:4567:890a]:2380',
            :initial_advertise_peer_urls => 'http://[fe80::1ff:fe23:4567:890a]:2380',
          )
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::etcd'
    end
  end
end
