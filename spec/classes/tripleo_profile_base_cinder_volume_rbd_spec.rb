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
            :backend_host                     => 'node.example.com',
            :rbd_ceph_conf                    => '/etc/ceph/ceph.conf',
            :rbd_pool                         => 'volumes',
            :rbd_user                         => 'openstack',
            :rbd_flatten_volume_from_snapshot => '<SERVICE DEFAULT>',
          )
        end
      end

      context 'with customizations' do
        before :each do
          params.merge!({
            :backend_name                            => 'poodles',
            :backend_availability_zone               => 'my_zone',
            :cinder_rbd_backend_host                 => 'fe80::fc54:ff:fe9e:7846',
            :cinder_rbd_ceph_conf                    => '/etc/ceph/mycluster.conf',
            :cinder_rbd_pool_name                    => 'poolname',
            :cinder_rbd_extra_pools                  => ['aplenty', 'galore'],
            :cinder_rbd_secret_uuid                  => 'secretuuid',
            :cinder_rbd_user_name                    => 'kcatsnepo',
            :cinder_rbd_flatten_volume_from_snapshot => true,
            :extra_options                           => {'poodles/param1' => { 'value' => 'value1' }},
          })
        end
        it 'should trigger complete configuration' do
          is_expected.to contain_cinder__backend__rbd('poodles').with(
            :backend_host                     => 'fe80::fc54:ff:fe9e:7846',
            :backend_availability_zone        => 'my_zone',
            :rbd_ceph_conf                    => '/etc/ceph/mycluster.conf',
            :rbd_pool                         => 'poolname',
            :rbd_user                         => 'kcatsnepo',
            :rbd_secret_uuid                  => 'secretuuid',
            :rbd_flatten_volume_from_snapshot => true,
            :extra_options                    => {'poodles/param1' => { 'value' => 'value1' }},
          )
          is_expected.to contain_cinder__backend__rbd('poodles_aplenty').with(
            :backend_host                     => 'fe80::fc54:ff:fe9e:7846',
            :backend_availability_zone        => 'my_zone',
            :rbd_ceph_conf                    => '/etc/ceph/mycluster.conf',
            :rbd_pool                         => 'aplenty',
            :rbd_user                         => 'kcatsnepo',
            :rbd_secret_uuid                  => 'secretuuid',
            :rbd_flatten_volume_from_snapshot => true,
            # extra_options are provided with only the first RBD backend/pool
            :extra_options                    => {},
          )
          is_expected.to contain_cinder__backend__rbd('poodles_galore').with(
            :backend_host                     => 'fe80::fc54:ff:fe9e:7846',
            :backend_availability_zone        => 'my_zone',
            :rbd_ceph_conf                    => '/etc/ceph/mycluster.conf',
            :rbd_pool                         => 'galore',
            :rbd_user                         => 'kcatsnepo',
            :rbd_secret_uuid                  => 'secretuuid',
            :rbd_flatten_volume_from_snapshot => true,
            :extra_options                    => {},
          )
        end
      end

      context 'with multiple backends' do
        before :each do
          params.merge!({
            :backend_name              => ['rbd1', 'rbd2'],
            :backend_availability_zone => 'zone1',
            :multi_config              => {
              'rbd2' => {
                'CinderRbdAvailabilityZone'          => 'zone2',
                'CephClusterName'                    => 'ceph2',
                'CinderRbdPoolName'                  => 'pool2a',
                'CinderRbdExtraPools'                => ['pool2b', 'pool2c'],
                'CephClusterFSID'                    => 'secretuuid',
                'CephClientUserName'                 => 'kcatsnepo',
                'CinderRbdFlattenVolumeFromSnapshot' => true,
              },
            },
            :extra_options                           => {'poodles/param1' => { 'value' => 'value1' }},
          })
        end
        it 'should configure each backend' do
          is_expected.to contain_cinder__backend__rbd('rbd1').with(
            :backend_host                     => 'node.example.com',
            :backend_availability_zone        => 'zone1',
            :rbd_ceph_conf                    => '/etc/ceph/ceph.conf',
            :rbd_pool                         => 'volumes',
            :rbd_user                         => 'openstack',
            :rbd_flatten_volume_from_snapshot => '<SERVICE DEFAULT>',
            :extra_options                    => {'poodles/param1' => { 'value' => 'value1' }},
          )

          is_expected.to contain_cinder__backend__rbd('rbd2').with(
            :backend_host                     => 'node.example.com',
            :backend_availability_zone        => 'zone2',
            :rbd_ceph_conf                    => '/etc/ceph/ceph2.conf',
            :rbd_pool                         => 'pool2a',
            :rbd_user                         => 'kcatsnepo',
            :rbd_secret_uuid                  => 'secretuuid',
            :rbd_flatten_volume_from_snapshot => true,
            # extra_options are provided with only the first RBD backend/pool
            :extra_options                    => {},
          )

          is_expected.to contain_cinder__backend__rbd('rbd2_pool2b').with(
            :backend_host                     => 'node.example.com',
            :backend_availability_zone        => 'zone2',
            :rbd_ceph_conf                    => '/etc/ceph/ceph2.conf',
            :rbd_pool                         => 'pool2b',
            :rbd_user                         => 'kcatsnepo',
            :rbd_secret_uuid                  => 'secretuuid',
            :rbd_flatten_volume_from_snapshot => true,
            :extra_options                    => {},
          )

          is_expected.to contain_cinder__backend__rbd('rbd2_pool2c').with(
            :backend_host                     => 'node.example.com',
            :backend_availability_zone        => 'zone2',
            :rbd_ceph_conf                    => '/etc/ceph/ceph2.conf',
            :rbd_pool                         => 'pool2c',
            :rbd_user                         => 'kcatsnepo',
            :rbd_secret_uuid                  => 'secretuuid',
            :rbd_flatten_volume_from_snapshot => true,
            :extra_options                    => {},
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
