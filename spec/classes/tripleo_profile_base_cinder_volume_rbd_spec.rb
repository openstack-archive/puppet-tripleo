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

describe 'tripleo::profile::base::cinder::volume::rbd' do
  shared_examples_for 'tripleo::profile::base::cinder::volume::rbd' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { { :step => 3 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume::rbd')
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_cinder__backend__rbd('tripleo_ceph')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :step => 4,
      } }

      context 'with defaults' do
        it 'should trigger complete configuration' do
          is_expected.to contain_cinder__backend__rbd('tripleo_ceph').with(
            :backend_host    => 'hostgroup',
            :rbd_pool        => 'volumes',
            :rbd_user        => 'openstack',
          )
        end
      end

      context 'with customizations' do
        before :each do
          params.merge!({
            :backend_name            => 'poodles',
            :cinder_rbd_backend_host => 'fe80::fc54:ff:fe9e:7846',
            :cinder_rbd_pool_name    => 'poolname',
            :cinder_rbd_extra_pools  => ['aplenty', 'galore'],
            :cinder_rbd_secret_uuid  => 'secretuuid',
            :cinder_rbd_user_name    => 'kcatsnepo'
          })
        end
        it 'should trigger complete configuration' do
          is_expected.to contain_cinder__backend__rbd('poodles').with(
            :backend_host    => 'fe80::fc54:ff:fe9e:7846',
            :rbd_pool        => 'poolname',
            :rbd_user        => 'kcatsnepo',
            :rbd_secret_uuid => 'secretuuid'
          )
          is_expected.to contain_cinder__backend__rbd('poodles_aplenty').with(
            :backend_host    => 'fe80::fc54:ff:fe9e:7846',
            :rbd_pool        => 'aplenty',
            :rbd_user        => 'kcatsnepo',
            :rbd_secret_uuid => 'secretuuid'
          )
          is_expected.to contain_cinder__backend__rbd('poodles_galore').with(
            :backend_host    => 'fe80::fc54:ff:fe9e:7846',
            :rbd_pool        => 'galore',
            :rbd_user        => 'kcatsnepo',
            :rbd_secret_uuid => 'secretuuid'
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

      it_behaves_like 'tripleo::profile::base::cinder::volume::rbd'
    end
  end
end
