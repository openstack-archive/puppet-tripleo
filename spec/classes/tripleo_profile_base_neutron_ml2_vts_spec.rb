#
# Copyright (C) 2017 Cisco, Inc.
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

describe 'tripleo::profile::base::neutron::plugins::ml2::vts' do
  let :params do
    { :step                    => 4
    }
  end
  shared_examples_for 'tripleo::profile::base::neutron::plugins::ml2::vts' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with IPv4 address' do
      before do
        params.merge!({
          :vts_url_ip => '192.0.2.5'
        })
      end
      it 'should configure vts ml2 plugin ' do
        is_expected.to contain_class('neutron::plugins::ml2::cisco::vts')
      end
    end

    context 'with IPv6 address' do
      before do
        params.merge!({
          :vts_url_ip => '2001:dead:beef::1'
        })
      end
      it 'should configure vts ml2 plugin' do
        is_expected.to contain_class('neutron::plugins::ml2::cisco::vts')
      end
    end

    context 'with no IP address' do
      it 'should not configure vts ml2 plugin' do
        is_expected.not_to contain_class('neutron::plugins::ml2::cisco::vts')
      end
    end

    context 'with VTS IPv4 and port 9999' do
      before do
        params.merge!({
          :vts_url_ip => '192.0.2.5',
          :vts_port => 9999
        })
      end
      it 'should contain VTS URL with port 9999' do
        is_expected.to contain_class('neutron::plugins::ml2::cisco::vts').with(
            :vts_url => "https://192.0.2.5:9999/api/running/openstack"

        )
      end
    end

    context 'with VTS IPv6 and port 9999' do
      before do
        params.merge!({
                          :vts_url_ip => '2001:15:dead::1',
                          :vts_port => 9999
                      })
      end
      it 'should contain VTS URL with port 9999' do
        is_expected.to contain_class('neutron::plugins::ml2::cisco::vts').with(
            :vts_url => "https://[2001:15:dead::1]:9999/api/running/openstack"

        )
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::plugins::ml2::vts'
    end
  end
end
