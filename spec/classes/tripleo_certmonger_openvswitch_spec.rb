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

describe 'tripleo::certmonger::openvswitch' do

  shared_examples_for 'tripleo::certmonger::openvswitch' do
    let :params do
      {
        :hostname            => 'localhost',
        :service_certificate => '/etc/pki/cert.crt',
        :service_key         => '/etc/pki/key.pem',
      }
    end

    it 'should include the base for using certmonger' do
      is_expected.to contain_class('certmonger')
    end

    it 'should request a certificate' do
      is_expected.to contain_certmonger_certificate('openvswitch').with(
        :ensure       => 'present',
        :certfile     => '/etc/pki/cert.crt',
        :keyfile      => '/etc/pki/key.pem',
        :hostname     => 'localhost',
        :dnsname      => 'localhost',
        :ca           => 'local',
        :wait         => true,
      )
      is_expected.to contain_file('/etc/pki/cert.crt').with(
        :owner   => 'openvswitch',
        :group   => 'hugetlbfs',
        :require => 'Certmonger_certificate[openvswitch]'
      )
      is_expected.to contain_file('/etc/pki/key.pem').with(
        :owner   => 'openvswitch',
        :group   => 'hugetlbfs',
        :require => 'Certmonger_certificate[openvswitch]'
      )
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::certmonger::openvswitch'
    end
  end
end
