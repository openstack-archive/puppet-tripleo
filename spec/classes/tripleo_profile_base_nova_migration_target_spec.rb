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

describe 'tripleo::profile::base::nova::migration::target' do
  shared_examples_for 'tripleo::profile::base::nova::migration::target' do

    context 'with step 4 without authorized_keys' do
      let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
eos
      }
      let(:params) { {
        :step           => 4,
        :services_enabled    => ['docker', 'nova_migration_target']
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_file('/etc/nova/migration/authorized_keys').with(
          :content => '# Migration over SSH disabled by TripleO',
          :mode    => '0640',
          :owner   => 'root',
          :group   => 'nova_migration',
        )
        is_expected.to contain_user('nova_migration').with(
          :shell => '/sbin/nologin'
        )
      }
    end

    context 'with step 4 without nova_migration_target service enabled' do
        let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
eos
      }
      let(:params) { {
        :step             => 4,
        :ssh_authorized_keys => ['bar', 'baz'],
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_file('/etc/nova/migration/authorized_keys').with(
          :content => '# Migration over SSH disabled by TripleO',
          :mode    => '0640',
          :owner   => 'root',
          :group   => 'nova_migration',
        )
        is_expected.to contain_user('nova_migration').with(
          :shell => '/sbin/nologin'
        )
      }
    end

    context 'with step 4 with invalid ssh_authorized_keys' do
        let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
eos
      }
      let(:params) { {
        :step             => 4,
        :ssh_authorized_keys => 'ssh-rsa bar',
      } }

      it { is_expected.to_not compile }
    end

    context 'with step 4 with nova_migration_target services enabled' do
        let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
eos
      }
      let(:params) { {
        :step                => 4,
        :ssh_authorized_keys => ['ssh-rsa bar', 'ssh-rsa baz'],
        :services_enabled    => ['docker', 'nova_migration_target']
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_ssh__server__match_block('nova_migration allow').with(
          :type  => 'User',
          :name  => 'nova_migration',
          :options => {
            'ForceCommand'           => '/bin/nova-migration-wrapper',
            'PasswordAuthentication' => 'no',
            'AllowTcpForwarding'     => 'no',
            'X11Forwarding'          => 'no',
            'AuthorizedKeysFile'     => '/etc/nova/migration/authorized_keys'
          }
        )
        is_expected.to_not contain_ssh__server__match_block('nova_migration deny')
        is_expected.to contain_file('/etc/nova/migration/authorized_keys').with(
          :content => 'ssh-rsa bar\nssh-rsa baz',
          :mode => '0640',
          :owner => 'root',
          :group => 'nova_migration',
        )
        is_expected.to contain_user('nova_migration').with(
          :shell => '/bin/bash'
        )
      }
    end

    context 'with step 4 with ssh_localaddrs' do
        let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
eos
      }
      let(:params) { {
        :step             => 4,
        :ssh_authorized_keys => ['ssh-rsa bar', 'ssh-rsa baz'],
        :services_enabled    => ['docker', 'nova_migration_target'],
        :ssh_localaddrs => ['127.0.0.1', '127.0.0.2']
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_ssh__server__match_block('nova_migration allow').with(
          :type  => 'LocalAddress 127.0.0.1,127.0.0.2 User',
          :name  => 'nova_migration',
          :options => {
            'ForceCommand'           => '/bin/nova-migration-wrapper',
            'PasswordAuthentication' => 'no',
            'AllowTcpForwarding'     => 'no',
            'X11Forwarding'          => 'no',
            'AuthorizedKeysFile'     => '/etc/nova/migration/authorized_keys'
          }
        )
        is_expected.to contain_ssh__server__match_block('nova_migration deny').with(
          :type  => 'LocalAddress',
          :name  => '!127.0.0.1,!127.0.0.2',
          :options => {
            'DenyUsers' => 'nova_migration'
          }
        )
        is_expected.to contain_file('/etc/nova/migration/authorized_keys').with(
          :content => 'ssh-rsa bar\nssh-rsa baz',
          :mode => '0640',
          :owner => 'root',
          :group => 'nova_migration',
        )
        is_expected.to contain_user('nova_migration').with(
          :shell => '/bin/bash'
        )
      }
    end

    context 'with step 4 with duplicate ssh_localaddrs' do
        let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
eos
      }
      let(:params) { {
        :step             => 4,
        :ssh_authorized_keys => ['ssh-rsa bar', 'ssh-rsa baz'],
        :services_enabled    => ['docker', 'nova_migration_target'],
        :ssh_localaddrs => ['127.0.0.1', '127.0.0.1']
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration')
        is_expected.to contain_ssh__server__match_block('nova_migration allow').with(
          :type  => 'LocalAddress 127.0.0.1 User',
          :name  => 'nova_migration',
          :options => {
            'ForceCommand'           => '/bin/nova-migration-wrapper',
            'PasswordAuthentication' => 'no',
            'AllowTcpForwarding'     => 'no',
            'X11Forwarding'          => 'no',
            'AuthorizedKeysFile'     => '/etc/nova/migration/authorized_keys'
          }
        )
        is_expected.to contain_ssh__server__match_block('nova_migration deny').with(
          :type  => 'LocalAddress',
          :name  => '!127.0.0.1',
          :options => {
            'DenyUsers' => 'nova_migration'
          }
        )
        is_expected.to contain_file('/etc/nova/migration/authorized_keys').with(
          :content => 'ssh-rsa bar\nssh-rsa baz',
          :mode => '0640',
          :owner => 'root',
          :group => 'nova_migration',
        )
        is_expected.to contain_user('nova_migration').with(
          :shell => '/bin/bash'
        )
      }
    end

    context 'with step 4 with invalid ssh_localaddrs' do
        let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
eos
      }
      let(:params) { {
        :step             => 4,
        :ssh_authorized_keys => ['ssh-rsa bar', 'ssh-rsa baz'],
        :services_enabled    => ['docker', 'nova_migration_target'],
        :ssh_localaddrs => ['127.0.0.1', '']
      } }

      it { is_expected.to_not compile }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end
      it_behaves_like 'tripleo::profile::base::nova::migration::target'
    end
  end
end