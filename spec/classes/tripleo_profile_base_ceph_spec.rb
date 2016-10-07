#
# Copyright (C) 2016 Red Hat, Inc.
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

describe 'tripleo::profile::base::ceph' do
  shared_examples_for 'tripleo::profile::base::ceph' do
    context 'with step less than 2' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to_not contain_class('ceph::conf')
        is_expected.to_not contain_class('ceph::profile::params')
      end
    end

    context 'with step 2' do
      let(:params) { {
        :step => 2,
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceph::profile::params').with(
          :mon_initial_members => nil,
          :mon_host            => '127.0.0.1'
        )
        is_expected.to contain_class('ceph::conf')
      end
    end

    context 'with step 2 with initial members' do
      let(:params) { {
        :step                     => 2,
        :ceph_mon_initial_members => [ 'monA', 'monB', 'monc' ]
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceph::profile::params').with(
          :mon_initial_members => 'mona,monb,monc',
          :mon_host => '127.0.0.1'
        )
        is_expected.to contain_class('ceph::conf')
      end
    end

    context 'with step 2 with ipv4 mon host' do
      let(:params) { {
        :step          => 2,
        :ceph_mon_host => ['10.0.0.1', '10.0.0.2']
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceph::profile::params').with(
          :mon_initial_members => nil,
          :mon_host => '10.0.0.1,10.0.0.2'
        )
        is_expected.to contain_class('ceph::conf')
      end
    end

    context 'with step 2 with ipv6 mon host' do
      let(:params) { {
        :step          => 2,
        :ceph_mon_host => ['fe80::fc54:ff:fe9e:7846', '10.0.0.2']
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceph::profile::params').with(
          :mon_initial_members => nil,
          :mon_host => '[fe80::fc54:ff:fe9e:7846],10.0.0.2'
        )
        is_expected.to contain_class('ceph::conf')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ceph'
    end
  end
end
