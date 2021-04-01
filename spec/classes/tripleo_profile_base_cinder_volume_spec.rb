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
      "
        class { 'tripleo::profile::base::cinder': step => #{params[:step]}, oslomsg_rpc_hosts => ['127.0.0.1'] }
      "
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
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_iscsi']
          )
        end
        it 'should not configure cinder-volume for A/A mode' do
          is_expected.to contain_class('cinder::volume').with(
            :cluster => '<SERVICE DEFAULT>',
          )
          is_expected.to_not contain_class('cinder::coordination')
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
        context 'with multiple pure backends' do
          # Step 5's hiera specifies two pure backend names
          let(:params) { { :step => 5 } }
          it 'should enable each backend' do
            is_expected.to contain_class('cinder::backends').with(
              :enabled_backends => ['tripleo_pure_1', 'tripleo_pure_2']
            )
          end
        end
      end

      context 'with only xtremio' do
        before :each do
          params.merge!({
            :cinder_enable_dellemc_xtremio_backend  => true,
            :cinder_enable_iscsi_backend            => false,
          })
        end
        it 'should configure only xtremio' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_xtremio')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellemc_xtremio']
          )
        end
        context 'with multiple xtremio backends' do
          # Step 5's hiera specifies two xtremio backend names
          let(:params) { { :step => 5 } }
          it 'should enable each backend' do
            is_expected.to contain_class('cinder::backends').with(
              :enabled_backends => ['tripleo_dellemc_xtremio_1', 'tripleo_dellemc_xtremio_2']
            )
          end
        end
      end

      context 'with only powermax' do
        before :each do
          params.merge!({
            :cinder_enable_dellemc_powermax_backend  => true,
            :cinder_enable_iscsi_backend             => false,
          })
        end
        it 'should configure only powermax' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_powermax')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellemc_powermax']
          )
        end
        context 'with multiple powermax backends' do
          # Step 5's hiera specifies two powermax backend names
          let(:params) { { :step => 5 } }
          it 'should enable each backend' do
            is_expected.to contain_class('cinder::backends').with(
              :enabled_backends => ['tripleo_dellemc_powermax_1', 'tripleo_dellemc_powermax_2']
            )
          end
        end
      end

      context 'with only powerstore' do
        before :each do
          params.merge!({
            :cinder_enable_dellemc_powerstore_backend  => true,
            :cinder_enable_iscsi_backend               => false,
          })
        end
        it 'should configure only powerstore' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_powerstore')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellemc_powerstore']
          )
        end
        context 'with multiple powerstore backends' do
          # Step 5's hiera specifies two powerstore backend names
          let(:params) { { :step => 5 } }
          it 'should enable each backend' do
            is_expected.to contain_class('cinder::backends').with(
              :enabled_backends => ['tripleo_dellemc_powerstore_1', 'tripleo_dellemc_powerstore_2']
            )
          end
        end
      end


      context 'with only sc' do
        before :each do
          params.merge!({
            :cinder_enable_dellemc_sc_backend  => true,
            :cinder_enable_iscsi_backend       => false,
          })
        end
        it 'should configure only sc' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_sc')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellemc_sc']
          )
        end
        context 'with multiple sc backends' do
          # Step 5's hiera specifies multiple sc backend names
          let(:params) { { :step => 5 } }
          it 'should enable each backend' do
            is_expected.to contain_class('cinder::backends').with(
              :enabled_backends => ['tripleo_dellemc_sc_1', 'tripleo_dellemc_sc_2']
            )
          end
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

     context 'with only powerflex' do
        before :each do
          params.merge!({
            :cinder_enable_dellemc_powerflex_backend => true,
            :cinder_enable_iscsi_backend            => false,
          })
        end
        it 'should configure only powerflex' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_powerflex')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellemc_powerflex']
          )
        end
      end

      context 'with only vxflexos' do
        before :each do
          params.merge!({
            :cinder_enable_dellemc_vxflexos_backend => true,
            :cinder_enable_iscsi_backend            => false,
          })
        end
        it 'should configure only vxflexos' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_vxflexos')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_dellemc_vxflexos']
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
        context 'with multiple netapp backends' do
          # Step 5's hiera specifies two netapp backend names
          let(:params) { { :step => 5 } }
          it 'should enable each backend' do
            is_expected.to contain_class('cinder::backends').with(
              :enabled_backends => ['tripleo_netapp_1', 'tripleo_netapp_2']
            )
          end
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
        context 'additional rbd pools and an additional rbd backend' do
          # Step 5's hiera specifies two rbd backends, each with additional rbd pools
          let(:params) { { :step => 5 } }
          it 'should configure additional rbd backends' do
            is_expected.to contain_class('cinder::backends').with(
              :enabled_backends => [
                'tripleo_ceph_1', 'tripleo_ceph_2', 'tripleo_ceph_1_foo', 'tripleo_ceph_1_bar', 'tripleo_ceph_2_zap',
              ]
            )
          end
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
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellemc_sc')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellemc_xtremio')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellsc')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellemc_powerflex')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellemc_powermax')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellemc_powerstore')
          is_expected.to_not contain_class('tripleo::profile::base::cinder::volume::dellemc_vxflexos')
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
            :cinder_enable_nfs_backend                => true,
            :cinder_enable_rbd_backend                => true,
            :cinder_enable_iscsi_backend              => true,
            :cinder_enable_pure_backend               => true,
            :cinder_enable_dellemc_powerflex_backend  => true,
            :cinder_enable_dellemc_powermax_backend   => true,
            :cinder_enable_dellemc_powerstore_backend => true,
            :cinder_enable_dellemc_sc_backend         => true,
            :cinder_enable_dellsc_backend             => true,
            :cinder_enable_dellemc_xtremio_backend    => true,
            :cinder_enable_dellemc_vxflexos_backend   => true,
            :cinder_enable_netapp_backend             => true,
            :cinder_enable_vrts_hs_backend            => true,
          })
        end
        it 'should configure all backends' do
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::iscsi')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::pure')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_sc')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_xtremio')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellsc')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_powerflex')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_powermax')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_powerstore')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_vxflexos')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::netapp')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::veritas_hyperscale')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::nfs')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume::rbd')
          is_expected.to contain_class('tripleo::profile::base::cinder::volume')
          is_expected.to contain_class('tripleo::profile::base::cinder')
          is_expected.to contain_class('cinder::volume')
          is_expected.to contain_class('cinder::backends').with(
            :enabled_backends => ['tripleo_iscsi', 'tripleo_ceph', 'tripleo_pure', 'tripleo_dellsc', 'tripleo_dellemc_sc','tripleo_dellemc_powerflex',
                                  'tripleo_dellemc_powermax', 'tripleo_dellemc_powerstore','tripleo_dellemc_vxflexos', 'tripleo_dellemc_xtremio',
                                  'tripleo_netapp','tripleo_nfs','Veritas_HyperScale']
          )
        end
      end

      context 'with a cluster name' do
        before :each do
          params.merge!({
            :cinder_volume_cluster => 'tripleo-cluster',
            :etcd_enabled          => true,
            :etcd_host             => '127.0.0.1',
          })
        end
        it 'should configure cinder-volume for A/A mode' do
          is_expected.to contain_class('cinder::volume').with(
            :cluster => 'tripleo-cluster',
          )
          is_expected.to contain_class('cinder::coordination').with(
            :backend_url => 'etcd3+http://127.0.0.1:2379',
          )
        end

        context 'with internal tls enabled' do
          before :each do
            params.merge!({
              :enable_internal_tls    => true,
              :etcd_certificate_specs => {
                'service_certificate' => '/path/to/etcd.cert',
                'service_key'         => '/path/to/etcd.key',
              },
            })
          end
          it 'should configure coordination backend_url with https' do
            is_expected.to contain_class('cinder::coordination').with(
              :backend_url => 'etcd3+https://127.0.0.1:2379?cert_key=/path/to/etcd.key&cert_cert=/path/to/etcd.cert',
            )
          end
        end

        context 'with an ipv6 etcd_host' do
          before :each do
            params.merge!({
              :etcd_host => 'fe80::1ff:fe23:4567:890a',
            })
          end
          it 'should normalize it in the URI' do
            is_expected.to contain_class('cinder::coordination').with(
              :backend_url => 'etcd3+http://[fe80::1ff:fe23:4567:890a]:2379',
            )
          end
        end

        context 'with a named etcd_host' do
          before :each do
            params.merge!({
              :etcd_host => 'etcdhost.localdomain',
            })
          end
          it 'should craft a correct URI' do
            is_expected.to contain_class('cinder::coordination').with(
              :backend_url => 'etcd3+http://etcdhost.localdomain:2379',
            )
          end
        end

        context 'with etcd service not enabled' do
          before :each do
            params.merge!({
              :etcd_enabled => false,
            })
          end
          it 'should fail to deploy' do
            is_expected.to compile.and_raise_error(
              /Running cinder-volume in active-active mode with a cluster name requires the etcd service./
            )
          end
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::cinder::volume'
    end
  end
end
