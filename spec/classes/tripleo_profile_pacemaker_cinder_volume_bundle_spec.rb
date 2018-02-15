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

describe 'tripleo::profile::pacemaker::cinder::volume_bundle' do
  shared_examples_for 'tripleo::profile::pacemaker::cinder::volume_bundle' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      # Required to keep tripleo::profile::base::cinder::volume happy.
      "class { 'tripleo::profile::base::cinder::volume::iscsi': step => #{params[:step]}, cinder_iscsi_address => ['127.0.0.1'] }"
    end

    context 'with step less than 2' do
      let(:params) { { :step => 1 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
      end
    end

    context 'with step 2 on bootstrap node' do
      let(:params) { {
        :step => 2,
      } }

      it 'should create pacemaker properties' do
        is_expected.to contain_pacemaker__property('cinder-volume-role-c-vol-1')
        is_expected.to contain_pacemaker__property('cinder-volume-role-c-vol-2')
      end
    end

    context 'with step 2 not on bootstrap node' do
      let(:params) { {
        :step           => 2,
        :bootstrap_node => 'other.example.com',
      } }

      it 'should not create pacemaker properties' do
        is_expected.to_not contain_pacemaker__property('cinder-volume-role-c-vol-1')
        is_expected.to_not contain_pacemaker__property('cinder-volume-role-c-vol-2')
      end
    end

    context 'with step 5' do
      let(:params) { {
        :step                       => 5,
        :cinder_volume_docker_image => 'c-vol-docker-image',
      } }

      context 'with default inputs' do
        it 'should create default cinder-volume resource bundle' do
          is_expected.to contain_pacemaker__resource__bundle('openstack-cinder-volume').with(
            :image   => 'c-vol-docker-image',
            :options => '--ipc=host --privileged=true --user=root --log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS',
          )
          # The default list of storage_maps is rather long, and this
          # just does a spot-check of a few key entries. The point is
          # to verify the default list is used when the docker_volumes
          # input parameter isn't specified.
          storage_maps = catalogue.resource(
            'Pacemaker::Resource::Bundle', 'openstack-cinder-volume').send(:parameters)[:storage_maps]
          expect(storage_maps).to include('cinder-volume-cfg-files',
                                          'cinder-volume-cfg-data')
        end
      end

      context 'with docker volumes and environment inputs' do
        before :each do
          params.merge!({
            :docker_volumes     => ['/src/1:/tgt/1', '/src/2:/tgt/2:ro', '/src/3:/tgt/3:ro,z'],
            :docker_environment => ['RIGHT=LEFT', 'UP=DOWN'],
          })
        end
        it 'should create custom cinder-volume resource bundle' do
          is_expected.to contain_pacemaker__resource__bundle('openstack-cinder-volume').with(
            :image        => 'c-vol-docker-image',
            :options      => '--ipc=host --privileged=true --user=root --log-driver=journald -e RIGHT=LEFT -e UP=DOWN',
            :storage_maps => {
              'cinder-volume-src-1' => {
                'source-dir' => '/src/1',
                'target-dir' => '/tgt/1',
                'options'    => 'rw',
              },
              'cinder-volume-src-2' => {
                'source-dir' => '/src/2',
                'target-dir' => '/tgt/2',
                'options'    => 'ro',
              },
              'cinder-volume-src-3' => {
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

      it_behaves_like 'tripleo::profile::pacemaker::cinder::volume_bundle'
    end
  end
end
