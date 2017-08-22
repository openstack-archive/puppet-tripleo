#
# Copyright (C) 2017 Red Hat Inc.
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
# Unit tests for tripleo
#

require 'spec_helper'

describe 'tripleo::certmonger::ca::crl' do

  shared_examples_for 'tripleo::certmonger::ca::crl' do

    context 'with default parameters (no crl_source)' do
      it 'should ensure no CRL nor cron job are present' do
        is_expected.to contain_file('tripleo-ca-crl').with(
          :ensure => 'absent'
        )
        is_expected.to contain_cron('tripleo-refresh-crl-file').with(
          :ensure => 'absent'
        )
      end
    end

    context 'with defined CRL source' do
      let :params do
        {
          :crl_dest         => '/etc/pki/CA/crl/overcloud-crl.pem',
          :crl_preprocessed => '/etc/pki/CA/crl/overcloud-crl.bin',
          :crl_source       => 'file://tmp/some/crl.bin',
        }
      end

      let :process_cmd do
        "openssl crl -in #{params[:crl_preprocessed]} -inform DER -outform PEM -out #{params[:crl_dest]}"
      end

      let :cron_cmd do
        "curl -s -L -o #{params[:crl_preprocessed]} #{params[:crl_source]} && #{process_cmd}"
      end

      it 'should create and process CRL file' do
        is_expected.to contain_file('tripleo-ca-crl').with(
          :ensure => 'present',
          :source => params[:crl_source]
        )
        is_expected.to contain_exec('tripleo-ca-crl-process-command').with(
          :command => process_cmd
        )
        is_expected.to contain_cron('tripleo-refresh-crl-file').with(
          :ensure  => 'present',
          :command => cron_cmd
        )
      end
    end

    context 'with defined CRL source and no processing' do
      let :params do
        {
          :crl_dest         => '/etc/pki/CA/crl/overcloud-crl.pem',
          :crl_source       => 'file://tmp/some/crl.pem',
          :process          => false
        }
      end

      let :cron_cmd do
        "curl -s -L -o #{params[:crl_dest]} #{params[:crl_source]}"
      end

      it 'should create and process CRL file' do
        is_expected.to contain_file('tripleo-ca-crl').with(
          :ensure => 'present',
          :source => params[:crl_source]
        )
        is_expected.to_not contain_exec('tripleo-ca-crl-process-command')
        is_expected.to contain_cron('tripleo-refresh-crl-file').with(
          :ensure  => 'present',
          :command => cron_cmd
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::certmonger::ca::crl'
    end
  end
end
