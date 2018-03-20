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

describe 'tripleo::certmonger::opendaylight' do

  let :params do
    {  :hostname            => 'localhost',
       :service_certificate => '/etc/pki/tls/certs/odl.crt',
       :service_key         => '/etc/pki/tls/private/odl.key',
    }
  end

  shared_examples_for 'tripleo::certmonger::opendaylight' do
    before :each do
      facts.merge!({ :step => 1 })
    end

    it 'should include the base for using certmonger' do
      is_expected.to contain_class('certmonger')
    end

    it 'should request a certificate' do
      is_expected.to contain_certmonger_certificate('opendaylight').with(
        :ensure       => 'present',
        :certfile     => params[:service_certificate],
        :keyfile      => params[:service_key],
        :hostname     => 'localhost',
        :dnsname      => 'localhost',
        :ca           => 'local',
        :wait         => true,
      )
      is_expected.to contain_file(params[:service_certificate]).with(
        :require => 'Certmonger_certificate[opendaylight]'
      )
      is_expected.to contain_file(params[:service_key]).with(
        :require => 'Certmonger_certificate[opendaylight]'
      )
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::certmonger::opendaylight'
    end
  end
end
