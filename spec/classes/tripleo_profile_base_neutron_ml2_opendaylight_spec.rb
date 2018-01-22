#
# Copyright (C) 2018 Red Hat, Inc.
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

describe 'tripleo::profile::base::neutron::plugins::ml2::opendaylight' do
  let :params do
    { :step         => 4,
      :odl_port     => 8081,
      :odl_username => 'dummy',
      :odl_password => 'dummy'
    }
  end
  shared_examples_for 'tripleo::profile::base::neutron::plugins::ml2::opendaylight' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with no TLS and API IP empty' do
      before do
        params.merge!({
          :odl_url_ip => '',
          :internal_api_fqdn   => [],
        })
      end
      it_raises 'a Puppet::Error',/OpenDaylight API VIP is Empty/
    end

    context 'with no TLS' do
      before do
        params.merge!({
          :odl_url_ip => '192.168.24.2',
          :internal_api_fqdn   => [],
        })
      end
      it 'should configure ML2' do
        is_expected.to contain_class('neutron::plugins::ml2::opendaylight').with(
          :odl_username => params[:odl_username],
          :odl_password => params[:odl_password],
          :odl_url      => "http://#{params[:odl_url_ip]}:#{params[:odl_port]}/controller/nb/v2/neutron"
        )
      end
    end

    context 'with TLS and FQDN empty' do
      before do
        params.merge!({
          :enable_internal_tls => true,
          :internal_api_fqdn   => [],
          :odl_url_ip          => '192.168.24.2'
        })
      end
      it_raises 'a Puppet::Error',/Internal API FQDN is Empty/
    end

    context 'with TLS' do
      before do
        params.merge!({
          :enable_internal_tls => true,
          :conn_proto          => 'https',
          :internal_api_fqdn   => 'example.cloud.org',
          :odl_url_ip          => '192.168.24.2'
        })
      end
      it 'should configure ML2' do
        is_expected.to contain_class('neutron::plugins::ml2::opendaylight').with(
          :odl_username => params[:odl_username],
          :odl_password => params[:odl_password],
          :odl_url      => "https://#{params[:internal_api_fqdn]}:#{params[:odl_port]}/controller/nb/v2/neutron"
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::plugins::ml2::opendaylight'
    end
  end
end
