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

describe 'tripleo::profile::base::nova::libvirt' do
  shared_examples_for 'tripleo::profile::base::nova::libvirt' do

    context 'with step less than 4' do
      let(:params) { { :step => 1, } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::libvirt')
        is_expected.to_not contain_class('tripleo::profile::base::nova')
        is_expected.to_not contain_class('nova::compute::libvirt::services')
        is_expected.to_not contain_file('/etclibvirt/qemu/networks/autostart/default.xml')
        is_expected.to_not contain_file('/etclibvirt/qemu/networks/default.xml')
        is_expected.to_not contain_exec('libvirt-default-net-destroy')
      }
    end

    context 'with step 4' do
      let(:pre_condition) do
        <<-eos
        class { '::tripleo::profile::base::nova':
          step => #{params[:step]},
          oslomsg_rpc_hosts => [ '127.0.0.1' ],
        }
eos
      end

      let(:params) { { :step => 4, } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::libvirt')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova::compute::libvirt::services')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/autostart/default.xml').with_ensure('absent')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/default.xml').with_ensure('absent')
        is_expected.to contain_exec('libvirt-default-net-destroy')
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::nova::libvirt'
    end
  end
end
