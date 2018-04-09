# Copyright 2018 Red Hat, Inc.
# All Rights Reserved.
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

describe 'tripleo::masquerade_networks' do

  let :params do
    { }
  end

  shared_examples_for 'tripleo::masquerade_networks' do

    context 'with masquerade networks enabled' do
      before :each do
        params.merge!(
          :masquerade_networks => {'192.168.24.0/24' => ['192.168.24.0/24', '192.168.25.0/24']},
        )
      end

      it 'configure RETURN rule' do
        is_expected.to contain_firewall('137 routed_network return 192.168.24.0/24 ipv4').with(
          :table       => 'nat',
          :source      => '192.168.24.0/24',
          :destination => ['192.168.24.0/24', '192.168.25.0/24'],
          :jump        => 'RETURN',
          :chain       => 'POSTROUTING',
          :proto       => 'all',
          :state       => ['ESTABLISHED', 'NEW', 'RELATED'],
        )
      end

      it 'configure MASQUERADE rule' do
        is_expected.to contain_firewall('138 routed_network masquerade 192.168.24.0/24 ipv4').with(
          :table       => 'nat',
          :source      => '192.168.24.0/24',
          :jump        => 'MASQUERADE',
          :chain       => 'POSTROUTING',
          :proto       => 'all',
          :state       => ['ESTABLISHED', 'NEW', 'RELATED'],
        )
      end

      it 'configure FORWARD rules' do
        is_expected.to contain_firewall('139 routed_network forward source 192.168.24.0/24 ipv4').with(
          :source      => '192.168.24.0/24',
          :chain       => 'FORWARD',
          :proto       => 'all',
          :state       => ['ESTABLISHED', 'NEW', 'RELATED'],
        )
        is_expected.to contain_firewall('140 routed_network forward destinations 192.168.24.0/24 ipv4').with(
          :destination => ['192.168.24.0/24', '192.168.25.0/24'],
          :chain       => 'FORWARD',
          :proto       => 'all',
          :state       => ['ESTABLISHED', 'NEW', 'RELATED'],
        )
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::masquerade_networks'
    end
  end
end
