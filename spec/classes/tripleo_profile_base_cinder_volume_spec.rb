# coding: utf-8
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

describe 'tripleo::profile::base::cinder::volume' do

  shared_examples_for 'tripleo::profile::base::cinder::volume' do
    # this hack allows hiera('step') to work as the spec hiera config will
    # allow any included modules to automagically get the right step from
    # hiera. (╯°□°)╯︵ ┻━┻
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      "class { '::tripleo::profile::base::cinder': step => #{params[:step]}, oslomsg_rpc_hosts => ['127.0.0.1'] }"
    end

    context 'with step less than 4' do
      let(:params) { { :step => 3 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_class('cinder::volume')
      end
    end

    context 'with step 4' do
      let(:params) { { :step => 4 } }

      context 'with defaults' do
        it 'should configure iscsi' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_iscsi']
          )
        end
      end

      context 'with only pure' do
        before :each do
          params.merge!({
            :cinder_enable_pure_backend  => true,
            :cinder_enable_iscsi_backend => false,
          })
        end
        it 'should configure only pure' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::pure')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_pure']
          )
        end
      end

      context 'with only dellsc' do
        before :each do
          params.merge!({
            :cinder_enable_dellsc_backend => true,
            :cinder_enable_iscsi_backend  => false,
          })
        end
        it 'should configure only dellsc' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellsc')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellsc']
          )
        end
      end

      context 'with only dellps' do
        before :each do
          params.merge!({
            :cinder_enable_dellps_backend => true,
            :cinder_enable_iscsi_backend  => false,
          })
        end
        it 'should configure only dellps' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellps')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellps']
          )
        end
      end

      context 'with only netapp' do
        before :each do
          params.merge!({
            :cinder_enable_netapp_backend => true,
            :cinder_enable_iscsi_backend  => false,
          })
        end
        it 'should configure only netapp' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::netapp')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_netapp']
          )
        end
      end

      context 'with only veritas hyperscale' do
        before :each do
          params.merge!({
            :cinder_enable_vrts_hs_backend => true,
            :cinder_enable_iscsi_backend   => false,
          })
        end
        it 'should configure only veritas hyperscale' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::veritas_hyperscale')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['Veritas_HyperScale']
          )
        end
      end

      context 'with only nfs' do
        before :each do
          params.merge!({
            :cinder_enable_nfs_backend   => true,
            :cinder_enable_iscsi_backend => false,
          })
        end
        it 'should configure only nfs' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::nfs')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_nfs']
          )
        end
      end

      context 'with only rbd' do
        before :each do
          params.merge!({
            :cinder_enable_rbd_backend   => true,
            :cinder_enable_iscsi_backend => false,
          })
        end
        it 'should configure only ceph' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::rbd')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_ceph']
          )
        end
      end

      context 'with only user backend' do
        before :each do
          params.merge!({
            :cinder_enable_iscsi_backend  => false,
            :cinder_user_enabled_backends => 'poodles'
          })
        end
        it 'should configure only user backend' do
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::pure')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellsc')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellps')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::netapp')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::veritas_hyperscale')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::nfs')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::rbd')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['poodles']
          )
        end
      end

      context 'with all tripleo backends' do
        before :each do
          params.merge!({
            :cinder_enable_nfs_backend     => true,
            :cinder_enable_rbd_backend     => true,
            :cinder_enable_iscsi_backend   => true,
            :cinder_enable_pure_backend    => true,
            :cinder_enable_dellsc_backend  => true,
            :cinder_enable_dellps_backend  => true,
            :cinder_enable_netapp_backend  => true,
            :cinder_enable_vrts_hs_backend => true,
          })
        end
        it 'should configure all backends' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::pure')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellsc')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellps')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::netapp')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::veritas_hyperscale')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::nfs')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::rbd')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_iscsi', 'tripleo_ceph', 'tripleo_pure', 'tripleo_dellps',
                                  'tripleo_dellsc', 'tripleo_netapp','tripleo_nfs','Veritas_HyperScale']
          )
        end
      end
    end
  end


  on_supported_os.each do |os, facts|
    context 'on #{os}' do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::cinder::volume'
    end
  end
end
