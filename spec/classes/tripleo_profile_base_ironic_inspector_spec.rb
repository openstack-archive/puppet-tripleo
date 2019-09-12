#
# Copyright (C) 2019 Red Hat, Inc.
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

describe 'tripleo::profile::base::ironic_inspector' do
  shared_examples_for 'tripleo::profile::base::ironic_inspector' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 3' do
      let(:params) { {
        :step           => 1,
        :bootstrap_node => 'node.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::ironic_inspector')
        is_expected.to_not contain_class('ironic::inspector')
        is_expected.to_not contain_class('ironic::inspector::pxe_filter')
        is_expected.to_not contain_class('ironic::inspector::pxe_filter::dnsmasq')
        is_expected.to_not contain_class('ironic::config')
        is_expected.to_not contain_class('ironic::inspector::logging')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step               => 3,
        :bootstrap_node     => 'node.example.com',
        :inspection_subnets => ['192.168.24.0/24'],
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::ironic_inspector')
        is_expected.to contain_class('ironic::inspector').with(
          :dnsmasq_ip_subnets => ['192.168.24.0/24']
        )
        is_expected.to contain_class('ironic::inspector::pxe_filter')
        is_expected.to contain_class('ironic::inspector::pxe_filter::dnsmasq')
        is_expected.to contain_class('ironic::config')
        is_expected.to contain_class('ironic::inspector::logging')
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::ironic_inspector')
        is_expected.to_not contain_class('ironic::inspector')
        is_expected.to_not contain_class('ironic::inspector::pxe_filter')
        is_expected.to_not contain_class('ironic::inspector::pxe_filter::dnsmasq')
        is_expected.to_not contain_class('ironic::config')
        is_expected.to_not contain_class('ironic::inspector::logging')
      }
    end

    context 'with step 4' do
      let(:params) { {
        :step               => 4,
        :bootstrap_node     => 'other.example.com',
        :inspection_subnets => ['192.168.24.0/24'],
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::ironic_inspector')
        is_expected.to contain_class('ironic::inspector').with(
          :dnsmasq_ip_subnets => ['192.168.24.0/24']
        )
        is_expected.to contain_class('ironic::inspector::pxe_filter')
        is_expected.to contain_class('ironic::inspector::pxe_filter::dnsmasq')
        is_expected.to contain_class('ironic::config')
        is_expected.to contain_class('ironic::inspector::logging')
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ironic_inspector'
    end
  end
end
