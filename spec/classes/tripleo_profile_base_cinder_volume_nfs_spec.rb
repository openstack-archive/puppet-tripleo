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

describe 'tripleo::profile::base::cinder::volume::nfs' do
  shared_examples_for 'tripleo::profile::base::cinder::volume::nfs' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :cinder_nfs_servers => ['127.0.0.1'],
        :step => 3
      } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume::nfs')
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_cinder__backend__nfs('tripleo_nfs')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :cinder_nfs_servers => ['127.0.0.1'],
        :step => 4,
      } }

      context 'with defaults' do
        it 'should trigger complete configuration' do
          is_expected.to contain_cinder__backend__nfs('tripleo_nfs').with(
            :nfs_servers => ['127.0.0.1'],
            :nfs_mount_options => '',
            :nfs_shares_config => '/etc/cinder/shares-nfs.conf'
          )
        end
      end

      context 'with customizations' do
        before :each do
          params.merge!(
            {
              :backend_availability_zone => 'my_zone',
            })
        end
        it 'should trigger complete configuration' do
          is_expected.to contain_cinder__backend__nfs('tripleo_nfs').with(
            :backend_availability_zone => 'my_zone',
          )
        end
      end

      context 'with selinux' do
        before :each do
          facts.merge!({ :selinux => 'true' })
        end
        it 'should configure selinux' do
          is_expected.to contain_selboolean('virt_use_nfs').with(
            :value => 'on',
            :persistent => true,
          )
        end
      end

      context 'without selinux' do
        before :each do
          facts.merge!({ :selinux => 'false' })
        end
        it 'should configure selinux' do
          is_expected.to_not contain_selboolean('virt_use_nfs')
        end
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::cinder::volume::nfs'
    end
  end
end
