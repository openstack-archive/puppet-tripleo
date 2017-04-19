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

describe 'tripleo::profile::base::nova' do
  shared_examples_for 'tripleo::profile::base::nova' do

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to_not contain_class('nova')
        is_expected.to_not contain_class('nova::config')
        is_expected.to_not contain_class('nova::cache')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step => 3,
        :bootstrap_node => 'node.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_username => 'nova',
        :messaging_password => 'foo',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => 'rabbit://nova:foo@localhost:5672/?ssl=0'
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::cache').with(
          :enabled => true,
          :backend => 'oslo_cache.memcache_pool',
          :memcache_servers => ['127.0.0.1:11211']
        )
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to_not contain_class('nova')
        is_expected.to_not contain_class('nova::config')
        is_expected.to_not contain_class('nova::cache')
        is_expected.to_not contain_class('nova::placement')
      }
    end

    context 'with step 4' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => /.+/,
          :notification_transport_url => /.+/,
          :nova_public_key => nil,
          :nova_private_key => nil,
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::cache')
        is_expected.to contain_class('nova::placement')
        is_expected.to_not contain_class('nova::migration::libvirt')
        is_expected.to contain_package('openstack-nova-migration').with(
          :ensure => 'absent'
        )
      }
    end

    context 'with step 4 with libvirt' do
      let(:pre_condition) {
        'include ::nova::compute::libvirt::services'
      }
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :manage_migration => true,
        :nova_compute_enabled => true,
        :bootstrap_node  => 'node.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => /.+/,
          :notification_transport_url => /.+/,
          :nova_public_key => nil,
          :nova_private_key => nil,
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::cache')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'ssh',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled]
        )
        is_expected.to contain_package('openstack-nova-migration').with(
          :ensure => 'absent'
        )
      }
    end

    context 'with step 4 with libvirt TLS' do
      let(:pre_condition) {
        'include ::nova::compute::libvirt::services'
      }
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :manage_migration => true,
        :nova_compute_enabled => true,
        :bootstrap_node  => 'node.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo',
        :libvirt_tls => true,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => /.+/,
          :notification_transport_url => /.+/,
          :nova_public_key => nil,
          :nova_private_key => nil,
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::cache')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'tls',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled],
        )
        is_expected.to contain_package('openstack-nova-migration').with(
          :ensure => 'absent'
        )
      }
    end

    context 'with step 4 with libvirt and migration ssh key' do
      let(:pre_condition) do
        <<-eof
        include ::nova::compute::libvirt::services
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
        eof
      end
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :manage_migration => true,
        :nova_compute_enabled => true,
        :bootstrap_node  => 'node.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo',
        :migration_ssh_key => { 'private_key' => 'foo', 'public_key' => 'ssh-rsa bar'}
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => /.+/,
          :notification_transport_url => /.+/,
          :nova_public_key  => nil,
          :nova_private_key => nil,
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::cache')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'ssh',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled]
        )
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
          :content => 'ssh-rsa bar',
          :mode => '0640',
          :owner => 'root',
          :group => 'nova_migration',
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => 'foo',
          :mode => '0600',
          :owner => 'nova',
          :group => 'nova',
        )
        is_expected.to contain_package('openstack-nova-migration').with(
          :ensure => 'installed'
        )
      }
    end

    context 'with step 4 with libvirt and migration ssh key and migration_ssh_localaddrs' do
      let(:pre_condition) do
        <<-eof
        include ::nova::compute::libvirt::services
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
        eof
      end
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :manage_migration => true,
        :nova_compute_enabled => true,
        :bootstrap_node  => 'node.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo',
        :migration_ssh_key => { 'private_key' => 'foo', 'public_key' => 'ssh-rsa bar'},
        :migration_ssh_localaddrs => ['127.0.0.1', '127.0.0.2']
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => /.+/,
          :notification_transport_url => /.+/,
          :nova_public_key  => nil,
          :nova_private_key => nil,
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::cache')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'ssh',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled]
        )
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
          :content => 'ssh-rsa bar',
          :mode => '0640',
          :owner => 'root',
          :group => 'nova_migration',
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => 'foo',
          :mode => '0600',
          :owner => 'nova',
          :group => 'nova',
        )
        is_expected.to contain_package('openstack-nova-migration').with(
          :ensure => 'installed'
        )
      }
    end

    context 'with step 4 with libvirt TLS and migration ssh key' do
      let(:pre_condition) do
        <<-eof
        include ::nova::compute::libvirt::services
        class { '::ssh::server':
          storeconfigs_enabled => false,
          options              => {}
        }
        eof
      end
      let(:params) { {
        :step           => 4,
        :libvirt_enabled => true,
        :manage_migration => true,
        :nova_compute_enabled => true,
        :bootstrap_node  => 'node.example.com',
        :messaging_hosts => [ 'localhost' ],
        :messaging_password => 'foo',
        :libvirt_tls => true,
        :migration_ssh_key => { 'private_key' => 'foo', 'public_key' => 'ssh-rsa bar'}
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => /.+/,
          :notification_transport_url => /.+/,
          :nova_public_key  => nil,
          :nova_private_key => nil,
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::cache')
        is_expected.to contain_class('nova::migration::libvirt').with(
          :transport         => 'tls',
          :configure_libvirt => params[:libvirt_enabled],
          :configure_nova    => params[:nova_compute_enabled]
        )
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
          :content => 'ssh-rsa bar',
          :mode => '0640',
          :owner => 'root',
          :group => 'nova_migration',
        )
        is_expected.to contain_file('/etc/nova/migration/identity').with(
          :content => 'foo',
          :mode => '0600',
          :owner => 'nova',
          :group => 'nova',
        )
        is_expected.to contain_package('openstack-nova-migration').with(
          :ensure => 'installed'
        )
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::nova'
    end
  end
end
