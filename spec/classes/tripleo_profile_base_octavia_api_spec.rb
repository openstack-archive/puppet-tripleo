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

describe 'tripleo::profile::base::octavia::api' do

  shared_examples_for 'tripleo::profile::base::octavia::api' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::octavia' :
        step => #{params[:step]},
        oslomsg_rpc_username => 'bugs',
        oslomsg_rpc_password => 'rabbits_R_c00l',
        oslomsg_rpc_hosts    => ['hole.field.com']
      }
      class { 'octavia::db::mysql':
        password => 'some_password'
      }
eos
    end

    context 'with step less than 3 on bootstrap' do
      let(:params) { {
        :step           => 2,
        :bootstrap_node => 'node.example.com'
      } }

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia::api')
        is_expected.to_not contain_class('octavia::controller')
        is_expected.to_not contain_class('octavia::healthcheck')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('octavia::wsgi::apache')
      end
    end

    context 'with step less than 3 on non-bootstrap' do
      let(:params) { {
        :step           => 2,
        :bootstrap_node => 'other.example.com'
      } }

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia::api')
        is_expected.to_not contain_class('octavia::controller')
        is_expected.to_not contain_class('octavia::healthcheck')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('octavia::wsgi::apache')
      end
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com'
      } }

      it 'should should start configurating database' do
        is_expected.to_not contain_class('octavia::api')
        is_expected.to_not contain_class('octavia::controller')
        is_expected.to_not contain_class('octavia::healthcheck')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('octavia::wsgi::apache')
      end
    end

    context 'with step 3 on non-bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com'
      } }

      it 'should do nothing' do
        is_expected.to_not contain_class('octavia::api')
        is_expected.to_not contain_class('octavia::controller')
        is_expected.to_not contain_class('octavia::healthcheck')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('octavia::wsgi::apache')
      end
    end

    context 'with step 4 on bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'node.example.com'
      } }

      it 'should apply configurations with syncing database' do
        is_expected.to contain_class('octavia::api').with(:sync_db => true)
        is_expected.to contain_class('octavia::controller')
        is_expected.to contain_class('octavia::healthcheck')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('octavia::wsgi::apache')
      end
    end

    context 'with step 4 on non-bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com'
      } }

      it 'should do nothing' do
        is_expected.to_not contain_class('octavia::api')
        is_expected.to_not contain_class('octavia::controller')
        is_expected.to_not contain_class('octavia::healthcheck')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('octavia::wsgi::apache')
      end
    end

    context 'with step 5 on non-bootstrap node' do
      let(:params) { {
        :step           => 5,
        :bootstrap_node => 'other.example.com'
      } }

      it 'should apply configurations without syncing database' do
        is_expected.to contain_class('octavia::api').with(:sync_db => false)
        is_expected.to contain_class('octavia::controller')
        is_expected.to contain_class('octavia::healthcheck')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('octavia::wsgi::apache')
      end
    end

    context 'Configure internal TLS' do
      let(:params) { {
        :step                 => 5,
        :bootstrap_node       => 'other.example.com',
        :enable_internal_tls  => true,
        :octavia_network      => 'octavia-net',
        :certificates_specs   => {
          'httpd-octavia-net' => {
            'hostname'            => 'somehost',
            'service_certificate' => '/foo.pem',
            'service_key'         => '/foo.key',
          },
        },
      } }

      it {
        is_expected.to contain_class('octavia::api')
        is_expected.to contain_class('octavia::controller')
        is_expected.to contain_class('octavia::healthcheck')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('octavia::wsgi::apache').with(
          :ssl_cert => '/foo.pem',
          :ssl_key  => '/foo.key',
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end
      it_behaves_like 'tripleo::profile::base::octavia::api'
    end
  end
end

