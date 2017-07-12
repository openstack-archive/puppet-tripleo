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

describe 'tripleo::profile::base::nova::migration::client' do
  shared_examples_for 'tripleo::profile::base::nova::migration::client' do

    context 'with step 4' do
      let(:pre_condition) {
        <<-eos
        include ::nova::compute::libvirt::services
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step           => 4,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'ssh',
          :configure_libvirt => false,
          :configure_nova    => false
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => '# Migration over SSH disabled by TripleO',
          :mode    => '0600',
          :owner   => 'nova',
          :group   => 'nova',
        )
      }
    end

    context 'with step 4 with libvirt' do
      let(:pre_condition) {
        <<-eos
        include ::nova::compute::libvirt::services
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :nova_compute_enabled => true,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'ssh',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled]
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => '# Migration over SSH disabled by TripleO',
          :mode    => '0600',
          :owner   => 'nova',
          :group   => 'nova',
        )
      }
    end

    context 'with step 4 with libvirt TLS' do
      let(:pre_condition) {
        <<-eos
        include ::nova::compute::libvirt::services
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :nova_compute_enabled => true,
        :libvirt_tls => true,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'tls',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled],
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => '# Migration over SSH disabled by TripleO',
          :mode    => '0600',
          :owner   => 'nova',
          :group   => 'nova',
        )
      }
    end

    context 'with step 4 with libvirt and migration ssh key' do
      let(:pre_condition) {
        <<-eos
        include ::nova::compute::libvirt::services
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :nova_compute_enabled => true,
        :ssh_private_key => 'foo'
      } }

      it {
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'ssh',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled]
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => 'foo',
          :mode => '0600',
          :owner => 'nova',
          :group => 'nova',
        )
      }
    end

    context 'with step 4 with libvirt TLS and migration ssh key' do
      let(:pre_condition) {
        <<-eos
        include ::nova::compute::libvirt::services
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :nova_compute_enabled => true,
        :libvirt_tls => true,
        :ssh_private_key => 'foo'
      } }

      it {
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'tls',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled]
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => 'foo',
          :mode => '0600',
          :owner => 'nova',
          :group => 'nova',
        )
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end
      it_behaves_like 'tripleo::profile::base::nova::migration::client'
    end
  end
end
