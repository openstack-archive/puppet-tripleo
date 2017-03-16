#
# Copyright (C) 2017 Red Hat Inc.
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

describe 'tripleo::certmonger::httpd' do

  shared_examples_for 'tripleo::certmonger::httpd' do
    let :params do
      {
        :name                => 'httpd-cert',
        :hostname            => 'localhost',
        :service_certificate => '/etc/pki/cert.crt',
        :service_key         => '/etc/pki/key.pem',
      }
    end

    it 'should include the base for using certmonger' do
      is_expected.to contain_class('certmonger')
    end

    it 'should include the httpd parameters' do
      is_expected.to contain_class('apache::params')
    end

    it 'should request a certificate' do
      is_expected.to contain_certmonger_certificate('httpd-cert').with(
        :ensure       => 'present',
        :certfile     => '/etc/pki/cert.crt',
        :keyfile      => '/etc/pki/key.pem',
        :hostname     => 'localhost',
        :dnsname      => 'localhost',
        :ca           => 'local',
        :wait         => true,
      )
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::certmonger::httpd'
    end
  end
end
