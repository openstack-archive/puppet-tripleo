#
# Copyright (C) 2020 Red Hat, Inc.
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

describe 'tripleo::profile::base::glance::backend::rbd' do
  shared_examples_for 'tripleo::profile::base::glance::backend::rbd' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :backend_names => ['my_rbd'],
        :step          => 3,
      } }

      it 'should not configure a backend' do
        is_expected.to contain_class('tripleo::profile::base::glance::backend::rbd')
        is_expected.to_not contain_glance__backend__multistore__rbd('my_rbd')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :backend_names => ['my_rbd'],
        :step          => 4,
      } }

      it 'should configure the backend' do
        is_expected.to contain_glance__backend__multistore__rbd('my_rbd').with(
          :rbd_store_ceph_conf => '/etc/ceph/ceph.conf',
          :rbd_store_user      => 'openstack',
          :rbd_store_pool      => 'images',
          :store_description   => 'RBD store',
        )
        is_expected.to contain_exec('exec-setfacl-ceph-openstack-glance').with_command(
          'setfacl -m u:glance:r-- /etc/ceph/ceph.client.openstack.keyring'
        )
        is_expected.to contain_exec('exec-setfacl-ceph-openstack-glance-mask').with_command(
          'setfacl -m m::r /etc/ceph/ceph.client.openstack.keyring'
        )
      end

      context 'with parameters overridden' do
        before :each do
          params.merge!({
            :rbd_store_chunk_size  => 512,
            :rbd_thin_provisioning => true,
            :rados_connect_timeout => 10,
          })

          it 'should configure the backend with the specified parameters' do
            is_expected.to contain_glance__backend__multistore__rbd('my_rbd').with(
              :rbd_store_ceph_conf   => '/etc/ceph/ceph.conf',
              :rbd_store_user        => 'openstack',
              :rbd_store_pool        => 'images',
              :rbd_store_chunk_size  => 512,
              :rbd_thin_provisioning => true,
              :rados_connect_timeout => 10,
              :store_description     => 'RBD store',
            )
          end
        end
      end

      context 'with store description in multistore_config' do
        before :each do
          params.merge!({
            :multistore_config => {
              'my_rbd' => {
                'GlanceStoreDescription' => 'My multistore RBD backend',
              },
            },
          })
        end
        it 'should use the multistore_config description' do
          is_expected.to contain_glance__backend__multistore__rbd('my_rbd').with(
            :store_description => 'My multistore RBD backend',
          )
        end
      end

      context 'with multiple backend_names' do
        before :each do
          params.merge!({
            :backend_names => ['rbd1', 'rbd2'],
            :multistore_config => {
              'rbd2' => {
                'CephClusterName'        => 'ceph2',
                'CephClientUserName'     => 'openstack2',
                'GlanceRbdPoolName'      => 'images2',
                'GlanceStoreDescription' => 'rbd2 backend',
              },
            },
            :store_description => 'rbd1 backend',
          })
        end
        it 'should configure multiple backends' do
          is_expected.to contain_glance__backend__multistore__rbd('rbd1').with(
            :rbd_store_ceph_conf => '/etc/ceph/ceph.conf',
            :rbd_store_user      => 'openstack',
            :rbd_store_pool      => 'images',
            :store_description   => 'rbd1 backend',
          )
          is_expected.to contain_glance__backend__multistore__rbd('rbd2').with(
            :rbd_store_ceph_conf => '/etc/ceph/ceph2.conf',
            :rbd_store_user      => 'openstack2',
            :rbd_store_pool      => 'images2',
            :store_description   => 'rbd2 backend',
          )
          is_expected.to contain_exec('exec-setfacl-ceph2-openstack2-glance').with_command(
            'setfacl -m u:glance:r-- /etc/ceph/ceph2.client.openstack2.keyring'
          )
          is_expected.to contain_exec('exec-setfacl-ceph2-openstack2-glance-mask').with_command(
            'setfacl -m m::r /etc/ceph/ceph2.client.openstack2.keyring'
          )
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::glance::backend::rbd'
    end
  end
end
