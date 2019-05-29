#
# Copyright (C) 2018 Red Hat, Inc.
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

describe 'tripleo::profile::pacemaker::manila::share_bundle' do
  shared_examples_for 'tripleo::profile::pacemaker::manila::share_bundle' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 2' do
      let(:params) { { :step => 1 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::manila::share')
      end
    end

    context 'with step 2 on bootstrap node' do
      let(:params) { {
        :step => 2,
      } }

      it 'should create pacemaker properties' do
        is_expected.to contain_pacemaker__property('manila-share-role-manila-1')
        is_expected.to contain_pacemaker__property('manila-share-role-manila-2')
      end
    end

    context 'with step 2 not on bootstrap node' do
      let(:params) { {
        :step           => 2,
        :bootstrap_node => 'other.example.com',
      } }

      it 'should not create pacemaker properties' do
        is_expected.to_not contain_pacemaker__property('manila-share-role-manila-1')
        is_expected.to_not contain_pacemaker__property('manila-share-role-manila-2')
      end
    end

    context 'with step 5' do
      let(:params) { {
        :step                      => 5,
        :manila_share_docker_image => 'manila-share-image',
      } }

      context 'with default inputs' do
        it 'should create default manila-share resource bundle' do
          is_expected.to contain_pacemaker__resource__bundle('openstack-manila-share').with(
            :image   => 'manila-share-image',
            :options => '--ipc=host --privileged=true --user=root --log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS',
          )
          # The default list of storage_maps is rather long, and this
          # just does a spot-check of a few key entries. The point is
          # to verify the default list is used when the docker_volumes
          # input parameter isn't specified.
          storage_maps = catalogue.resource(
            'Pacemaker::Resource::Bundle', 'openstack-manila-share').send(:parameters)[:storage_maps]
          expect(storage_maps).to include('manila-share-cfg-files', 'manila-share-cfg-data')
          # ceph-nfs is disabled by default, so ensure no resources are created.
          is_expected.to_not contain_pacemaker__constraint__order('ceph-nfs-then-manila-share')
          is_expected.to_not contain_pacemaker__constraint__colocation('openstack-manila-share-with-ceph-nfs')
          expect(storage_maps).to_not include('manila-share-dbus-docker', 'manila-share-etc-ganesha')
        end
      end

      context 'with ceph-nfs enabled' do
        before :each do
          params.merge!({
            :ceph_nfs_enabled => true,
          })
        end
        it 'should include ceph-nfs docker volumes and pacemaker constraints' do
          is_expected.to contain_pacemaker__constraint__order('ceph-nfs-then-manila-share')
          is_expected.to contain_pacemaker__constraint__colocation('openstack-manila-share-with-ceph-nfs')
          storage_maps = catalogue.resource(
            'Pacemaker::Resource::Bundle', 'openstack-manila-share').send(:parameters)[:storage_maps]
          expect(storage_maps).to include('manila-share-dbus-docker', 'manila-share-etc-ganesha')
        end
      end

      context 'with docker volumes and environment inputs' do
        before :each do
          params.merge!({
            :docker_volumes     => ['/src/1:/tgt/1', '/src/2:/tgt/2:ro', '/src/3:/tgt/3:ro,z'],
            :docker_environment => ['RIGHT=LEFT', 'UP=DOWN'],
          })
        end
        it 'should create custom manila-share resource bundle' do
          is_expected.to contain_pacemaker__resource__bundle('openstack-manila-share').with(
            :image        => 'manila-share-image',
            :options      => '--ipc=host --privileged=true --user=root --log-driver=journald -e RIGHT=LEFT -e UP=DOWN',
            :storage_maps => {
              'manila-share-src-1' => {
                'source-dir' => '/src/1',
                'target-dir' => '/tgt/1',
                'options'    => 'rw',
              },
              'manila-share-src-2' => {
                'source-dir' => '/src/2',
                'target-dir' => '/tgt/2',
                'options'    => 'ro',
              },
              'manila-share-src-3' => {
                'source-dir' => '/src/3',
                'target-dir' => '/tgt/3',
                'options'    => 'ro,z',
              },
            },
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

      it_behaves_like 'tripleo::profile::pacemaker::manila::share_bundle'
    end
  end
end
