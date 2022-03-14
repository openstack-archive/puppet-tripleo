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

describe 'tripleo::profile::base::memcached' do
  shared_examples_for 'tripleo::profile::base::memcached' do
    context 'with step 0' do
      let(:params) { {
        :step => 0,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::memcached')
        is_expected.to_not contain_class('memcached')
      }
    end

    context 'with step 1' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::memcached')
        is_expected.to contain_class('memcached').with(
          :use_tls        => false,
          :tls_cert_chain => nil,
          :tls_key        => nil
        )
      }
    end

    context 'with step 1 and tls enabled' do
      let(:params) { {
        :step                          => 1,
        :enable_internal_memcached_tls => true,
        :certificate_specs             => {
          'service_certificate' => '/etc/pki/cert.crt',
          'service_key'         => '/etc/pki/key.pem'}
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::memcached')
        is_expected.to contain_class('memcached').with(
          :use_tls        => true,
          :tls_cert_chain => '/etc/pki/cert.crt',
          :tls_key        => '/etc/pki/key.pem'
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::memcached'
    end
  end
end
