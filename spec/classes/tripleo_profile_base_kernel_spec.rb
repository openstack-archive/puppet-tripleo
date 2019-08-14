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

describe 'tripleo::profile::base::kernel' do

    shared_examples_for 'tripleo::profile::base::kernel' do
        context 'with kernel modules' do
           let :params do
               {
                   :module_list => {
                     'nf_conntrack' => {},
                   }
               }
           end

            it 'should load kernel module' do
                is_expected.to contain_kmod__load('nf_conntrack')
            end
        end
        context 'with packages' do
           let :params do
               {
                   :package_list => {
                     'kmod_special' => {},
                   }
               }
           end

            it 'should install package' do
              is_expected.to contain_package('kmod_special').with('tag' => 'kernel-package')
            end
        end
        context 'with sysctl settings' do
           let :params do
               {
                   :sysctl_settings => {
                     'net.ipv4.tcp_keepalive_intvl' => { 'value' => '1'},
                   }
               }
           end

            it 'should load kernel module' do
                is_expected.to contain_sysctl__value('net.ipv4.tcp_keepalive_intvl')
            end
        end
    end

    on_supported_os.each do |os, facts|
        context "on #{os}" do
            let(:facts) {
                facts
            }

        it_behaves_like 'tripleo::profile::base::kernel'
        end
    end
end
