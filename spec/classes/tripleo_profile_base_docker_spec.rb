# Copyright 2016 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#

require 'spec_helper'

describe 'tripleo::profile::base::docker' do
  shared_examples_for 'tripleo::profile::base::docker' do
    context 'with step 1 and defaults' do
      let(:params) { {
          :step              => 1,
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
          is_expected.to contain_augeas('docker-sysconfig-options').with_changes([
            "set OPTIONS '\"--log-driver=journald --signature-verification=false\"'",
          ])
      }
    end

    context 'with step 1 and insecure_registry configured' do
      let(:params) { {
          :docker_namespace  => 'foo:8787',
          :insecure_registry => true,
          :step              => 1,
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
        is_expected.to contain_augeas('docker-sysconfig-registry').with_changes([
          "set INSECURE_REGISTRY '\"--insecure-registry foo:8787\"'",
        ])
      }
    end

    context 'with step 1 and insecure_registry configured but no docker_namespace' do
      let(:params) { {
          :insecure_registry => true,
          :step              => 1,
      } }

      it_raises 'a Puppet::Error', /You must provide a \$docker_namespace in order to configure insecure registry/
    end

    context 'with step 1 and registry_mirror configured' do
      let(:params) { {
          :registry_mirror => 'http://foo/bar',
          :step              => 1,
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
        is_expected.to contain_augeas('docker-daemon.json').with_changes(['set dict/entry[. = "registry-mirrors"] "registry-mirrors', "set dict/entry[. = \"registry-mirrors\"]/array/string \"http://foo/bar\""])
      }
    end

    context 'with step 1 and docker_options configured' do
      let(:params) { {
          :docker_options    => '--log-driver=syslog',
          :step              => 1,
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
        is_expected.to contain_augeas('docker-sysconfig-options').with_changes([
          "set OPTIONS '\"--log-driver=syslog\"'",
        ])
      }
    end

    context 'with step 1 and storage_options configured' do
      let(:params) { {
          :step              => 1,
          :storage_options   => '-s devicemapper',
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
        is_expected.to contain_augeas('docker-sysconfig-storage').with_changes([
          "set DOCKER_STORAGE_OPTIONS '\" #{params[:storage_options]}\"'",
        ])
      }
    end

    context 'with step 1 and configure_storage disabled' do
      let(:params) { {
          :step              => 1,
          :configure_storage => false,
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
        is_expected.to contain_augeas('docker-sysconfig-storage').with_changes([
          "rm DOCKER_STORAGE_OPTIONS",
        ])
      }
    end

    context 'with step 4 and configure_libvirt_polkit disabled' do
      let(:params) { {
          :step                    => 4,
          :configure_libvirt_polkit => false
      } }
      it {
        is_expected.to_not contain_group('docker_nova_group')
        is_expected.to_not contain_user('docker_nova_user')
        is_expected.to_not contain_package('polkit')
        is_expected.to_not contain_file('/etc/polkit-1/rules.d/50-nova.rules')
      }
    end

    context 'with step 4 and configure_libvirt_polkit enabled' do
      let(:params) { {
          :step                    => 4,
          :configure_libvirt_polkit => true
      } }
      it {
        is_expected.to contain_group('docker_nova_group').with(
          :name => 'docker_nova',
          :gid  => 42436
        )
        is_expected.to contain_user('docker_nova_user').with(
          :name => 'docker_nova',
          :uid  => 42436,
          :gid  => 42436,
          :shell => '/sbin/nologin',
          :groups => ['nobody']
        )
        is_expected.to contain_package('polkit')
        is_expected.to contain_file('/etc/polkit-1/rules.d/50-nova.rules')
      }
    end

    context 'with step 4 and nova_compute service installed' do
      let(:params) { {
          :step          => 4,
          :services_enabled => ['docker', 'nova_compute']
      } }
      it {
        is_expected.to contain_group('docker_nova_group').with(
          :name => 'docker_nova',
          :gid  => 42436
        )
        is_expected.to contain_user('docker_nova_user').with(
          :name => 'docker_nova',
          :uid  => 42436,
          :gid  => 42436,
          :shell => '/sbin/nologin',
          :groups => ['nobody']
        )
        is_expected.to contain_package('polkit')
        is_expected.to contain_file('/etc/polkit-1/rules.d/50-nova.rules')
      }
    end

    context 'with step 4 and configure_libvirt_polkit enabled and docker_nova uid' do
      let(:params) { {
          :step                    => 4,
          :configure_libvirt_polkit => true,
          :docker_nova_uid         => 12345
      } }
      it {
        is_expected.to contain_group('docker_nova_group').with(
          :name => 'docker_nova',
          :gid  => 12345
        )
        is_expected.to contain_user('docker_nova_user').with(
          :name => 'docker_nova',
          :uid  => 12345,
          :gid  => 12345,
          :shell => '/sbin/nologin',
          :groups => ['nobody']
        )
        is_expected.to contain_package('polkit')
        is_expected.to contain_file('/etc/polkit-1/rules.d/50-nova.rules')
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::docker'
    end
  end
end
