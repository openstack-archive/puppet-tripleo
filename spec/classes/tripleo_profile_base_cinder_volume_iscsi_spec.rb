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

describe 'tripleo::profile::base::cinder::volume::iscsi' do
  shared_examples_for 'tripleo::profile::base::cinder::volume::iscsi' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :cinder_iscsi_address => '127.0.0.1',
        :step => 3
      } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume::iscsi')
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_class('cinder::setup_test_volume')
        is_expected.to_not contain_cinder__backend__iscsi('tripleo_iscsi')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :cinder_iscsi_address => '127.0.0.1',
        :step => 4,
      } }

      context 'with defaults' do
        it 'should trigger complete configuration' do
          is_expected.to contain_class('cinder::setup_test_volume').with(
            :size => '10280M'
          )
          is_expected.to contain_cinder__backend__iscsi('tripleo_iscsi').with(
            :iscsi_ip_address => '127.0.0.1',
            :iscsi_helper     => 'tgtadm',
            :iscsi_protocol   => 'iscsi'
          )
        end
      end

      context 'with ipv6 address' do
        before :each do
          params.merge!({ :cinder_iscsi_address => 'fe80::fc54:ff:fe9e:7846' })
        end
        it 'should trigger complete configuration' do
          is_expected.to contain_class('cinder::setup_test_volume').with(
            :size => '10280M'
          )
          is_expected.to contain_cinder__backend__iscsi('tripleo_iscsi').with(
            :iscsi_ip_address => '[fe80::fc54:ff:fe9e:7846]'
          )
        end
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::cinder::volume::iscsi'
    end
  end
end
