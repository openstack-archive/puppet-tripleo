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

describe 'tripleo::profile::base::barbican::backends' do
  shared_examples_for 'tripleo::profile::base::barbican::backends' do
    context 'with simple_crypto plugin only enabled' do
      let(:params) { { :simple_crypto_backend_enabled => true } }
      it 'should configure simple_crypto' do
        is_expected.to contain_class('barbican::plugins::simple_crypto')
        expect('tripleo::profile::base::barbican::backends::enabled_secret_stores').to be('simple_crypto')
      end
    end

    context 'with dogtag plugin only enabled' do
      let(:params) { { :dogtag_backend_enabled => true } }
      it 'should configure dogtag backend' do
        is_expected.to contain_class('barbican::plugins::dogtag')
        expect('tripleo::profile::base::barbican::backends::enabled_secret_stores').to be('dogtag')
      end
    end

    context 'with p11_crypto plugin only enabled' do
      let(:params) { { :p11_crypto_backend_enabled => true } }
      it 'should configure p11_crypto' do
        is_expected.to contain_class('barbican::plugins::p11_crypto')
        expect('tripleo::profile::base::barbican::backends::enabled_secret_stores').to be('pkcs11')
      end
    end

    context 'with kmip plugin only enabled' do
      let(:params) { { :kmip_backend_enabled => true } }
      it 'should configure kmip' do
        is_expected.to contain_class('barbican::plugins::kmip')
        expect('tripleo::profile::base::barbican::backends::enabled_secret_stores').to be('kmip')
      end
    end

    context 'with simple_crypto and dogtag enabled' do
      let(:params) { {
        :simple_crypto_backend_enabled => true,
        :dogtag_backend_enabled => true,
      } }
      it 'should configure simple_crypto and dogtag' do
        is_expected.to contain_class('barbican::plugins::simple_crypto')
        is_expected.to contain_class('barbican::plugins::dogtag')
        expect('tripleo::profile::base::barbican::backends::enabled_secret_stores').to be('simple_crypto,dogtag')
      end
    end

    context 'with simple_crypto plugin and p11_crypto enabled' do
      let(:params) { {
        :simple_crypto_backend_enabled => true,
        :p11_crypto_backend_enabled => true,
      } }
      it 'should configure simple_crypto and p11_crypto' do
        is_expected.to contain_class('barbican::plugins::simple_crypto')
        is_expected.to contain_class('barbican::plugins::p11_crypto')
        expect('tripleo::profile::base::barbican::backends::enabled_secret_stores').to be('simple_crypto,pkcs11')
      end
    end

    context 'with all plugins enabled' do
      let(:params) { {
        :simple_crypto_backend_enabled => true,
        :p11_crypto_backend_enabled => true,
        :dogtag_backend_enabled => true,
        :kmip_backend_enabled => true,
      } }
      it 'should configure all plugins' do
        is_expected.to contain_class('barbican::plugins::simple_crypto')
        is_expected.to contain_class('barbican::plugins::p11_crypto')
        is_expected.to contain_class('barbican::plugins::dogtag')
        is_expected.to contain_class('barbican::plugins::kmip')
        expect('tripleo::profile::base::barbican::backends::enabled_secret_stores').to be(
         'simple_crypto,dogtag,pkcs11,kmip')
      end
    end

  end
end
