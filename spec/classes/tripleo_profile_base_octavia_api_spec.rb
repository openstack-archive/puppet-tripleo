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

  let :params do
    { :step            => 5,
      :bootstrap_node  => 'notbootstrap.example.com'
    }
  end

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
      class { 'octavia::keystone::authtoken':
        password => 'some_password'
      }
eos
    end

    context 'with step less than 3 on bootstrap' do
      before do
        params.merge!({
          :step           => 2,
          :bootstrap_node => 'node.example.com'
        })
      end

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia::api')
      end
    end

    context 'with step less than 3 on non-bootstrap' do
      before do
        params.merge!({ :step => 2 })
      end

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia::api')
      end
    end

    context 'with step 3 on bootstrap node' do
      before do
        params.merge!({
          :step           => 3,
          :bootstrap_node => 'node.example.com'
        })
      end

      it 'should should start configurating database' do
        is_expected.to_not contain_class('octavia::api')
      end
    end

    context 'with step 3 on non-bootstrap node' do
      before do
        params.merge!({ :step => 3 })
      end

      it 'should do nothing' do
        is_expected.to_not contain_class('octavia::api')
      end
    end

    context 'with step 4 on bootstrap node' do
      before do
        params.merge!({
          :step           => 4,
          :bootstrap_node => 'node.example.com'
        })
      end

      it 'should should sync database' do
        is_expected.to contain_class('octavia::api').with(:sync_db => true)
      end
    end

    context 'with step 4 on non-bootstrap node' do
      before do
        params.merge!({ :step => 4 })
      end

      it 'should do nothing' do
        is_expected.to_not contain_class('octavia::api')
      end
    end

    context 'with step 5 on non-bootstrap node' do
      before do
        params.merge!({ :step => 5 })
      end

      it 'should do nothing' do
        is_expected.to contain_class('octavia::api').with(:sync_db => false)
      end
    end

    context 'Configure internal TLS' do
      before do
        params.merge!({
          :step                 => 5,
          :bootstrap_node       => 'node.example.com',
          :enable_internal_tls  => true,
          :octavia_network      => 'octavia-net',
          :certificates_specs   => {
            'httpd-octavia-net' => {
              'hostname'            => 'somehost',
              'service_certificate' => '/foo.pem',
              'service_key'         => '/foo.key',
            },
          },
          :tls_proxy_bind_ip    => '172.16.10.25',
          :tls_proxy_fqdn       => 'octavia-host.example.com',
          :tls_proxy_port       => 9876
        })
      end
      it {
        is_expected.to contain_class('octavia::api')
        is_expected.to contain_apache__vhost('octavia-api-proxy').with(
          :ssl_cert     => '/foo.pem',
          :ssl_key      => '/foo.key',
          :ip           => '172.16.10.25',
          :port         => 9876,
          :servername   => 'octavia-host.example.com',
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

