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

describe 'tripleo::profile::base::database::mysql::client' do
  shared_examples_for 'tripleo::profile::base::database::mysql::client' do

    context 'with defaults' do
      let (:params) do
        { :step => 1 }
      end

      before (:each) do
        facts.merge!({ :uuid => 'notdocker' })
      end

      it {
        is_expected.to contain_exec('directory-create-etc-my.cnf.d')
        is_expected.to contain_file('/etc/my.cnf.d/tripleo.cnf').with(
          :ensure => 'file',
        )
        is_expected.to contain_augeas('tripleo-mysql-client-conf').with(
          :incl    => '/etc/my.cnf.d/tripleo.cnf',
          :changes => [
            'rm tripleo/bind-address',
            'rm tripleo/ssl',
            'rm tripleo/ssl-ca',
            'rm client/ssl',
            'rm client/ssl-ca'
          ]
        )
      }
    end

    context 'with defaults on docker' do
      let (:params) do
        { :step => 1 }
      end

      before (:each) do
        facts.merge!({ :uuid => 'docker' })
      end

      it {
        is_expected.to contain_file('/etc/my.cnf.d').with(:ensure => 'directory')
        is_expected.to contain_augeas('tripleo-mysql-client-conf').with(
          :incl    => '/etc/my.cnf.d/tripleo.cnf',
          :changes => [
            'rm tripleo/bind-address',
            'rm tripleo/ssl',
            'rm tripleo/ssl-ca',
            'rm client/ssl',
            'rm client/ssl-ca'
          ]
        )
      }
    end

    context 'with defaults with deployment_type' do
      let (:params) do
        { :step => 1 }
      end

      before (:each) do
        facts.merge!({ :uuid => 'notdocker', :deployment_type => 'containers' })
      end

      it {
        is_expected.to contain_file('/etc/my.cnf.d').with(:ensure => 'directory')
        is_expected.to contain_augeas('tripleo-mysql-client-conf').with(
          :incl    => '/etc/my.cnf.d/tripleo.cnf',
          :changes => [
            'rm tripleo/bind-address',
            'rm tripleo/ssl',
            'rm tripleo/ssl-ca',
            'rm client/ssl',
            'rm client/ssl-ca'
          ]
        )
      }
    end

    context 'with ip address set to "" LP#1748180' do
      let (:params) do
        { :step => 1,
          :mysql_client_bind_address => ''
        }
      end

      before (:each) do
        facts.merge!({ :uuid => 'notdocker' })
      end

      it {
        is_expected.to contain_exec('directory-create-etc-my.cnf.d')
        is_expected.to contain_augeas('tripleo-mysql-client-conf').with(
          :incl    => '/etc/my.cnf.d/tripleo.cnf',
          :changes => [
            'rm tripleo/bind-address',
            'rm tripleo/ssl',
            'rm tripleo/ssl-ca',
            'rm client/ssl',
            'rm client/ssl-ca'
          ]
        )
      }
    end

    context 'with ip address and ssl enabled' do
      let (:params) do
        { :step => 1,
          :enable_ssl                => true,
          :mysql_client_bind_address => '127.0.0.1'
        }
      end

      before (:each) do
        facts.merge!({ :uuid => 'notdocker' })
      end

      it {
        is_expected.to contain_exec('directory-create-etc-my.cnf.d')
        is_expected.to contain_augeas('tripleo-mysql-client-conf').with(
          :incl    => '/etc/my.cnf.d/tripleo.cnf',
          :changes => [
            "set tripleo/bind-address '#{params[:mysql_client_bind_address]}'",
            "set tripleo/ssl '1'",
            "set tripleo/ssl-ca '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt'",
            "set client/ssl '1'",
            "set client/ssl-ca '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt'"
          ]
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::database::mysql::client'
    end
  end
end
