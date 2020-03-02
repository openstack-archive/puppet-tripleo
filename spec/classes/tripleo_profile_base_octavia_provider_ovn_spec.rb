#
# Copyright (C) 2020 Red Hat, Inc.
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

describe 'tripleo::profile::base::octavia::provider::ovn' do

  let :params do
    { :step => 5,
    }
  end

  shared_examples_for 'tripleo::profile::base::octavia::provider::ovn' do
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
      class { 'tripleo::profile::base::octavia::api' :
        step => #{params[:step]},
        bootstrap_node  => 'notbootstrap.example.com',
      }
eos
    end

    context 'with step less than 3' do
      before do
        params.merge!({
          :step => 2,
        })
      end

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia::provider::ovn')
      end
    end

    context 'with step 4 without ovn_db_host' do
      before do
        params.merge!({
          :step        => 4,
          :protocol    => 'tcp',
          :ovn_nb_port => '6641',
        })
      end

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia::provider::ovn')
      end
    end

    context 'with step 4 with ovn default protocol' do
      before do
        params.merge!({
          :step        => 4,
          :ovn_db_host => '127.0.0.1',
          :ovn_nb_port => '6641',
        })
      end

      it 'should set octavia provider ovn nb connection using tcp' do
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_connection  => 'tcp:127.0.0.1:6641')
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_private_key => '<SERVICE DEFAULT>')
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_certificate => '<SERVICE DEFAULT>')
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_ca_cert     => '<SERVICE DEFAULT>')
      end
    end

    context 'with step 4 with ovn and tls/ssl' do
      before do
        params.merge!({
          :step               => 4,
          :protocol           => 'ssl',
          :ovn_db_host        => '192.168.123.111',
          :ovn_nb_port        => '6641',
          :ovn_nb_private_key => '/foo.key',
          :ovn_nb_certificate => '/foo.pem',
          :ovn_nb_ca_cert     => '/ca_foo.pem',
        })
      end

      it 'should set octavia provider ovn nb connection using ssl' do
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_connection  => 'ssl:192.168.123.111:6641')
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_private_key => '/foo.key')
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_certificate => '/foo.pem')
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_ca_cert     => '/ca_foo.pem')
      end
    end

    context 'with step 4 with ovn and unix socket (no ovn_nb_port)' do
      before do
        params.merge!({
          :step        => 4,
          :protocol    => 'punix',
          :ovn_db_host => '/run/ovn/ovnnb_db.sock',
        })
      end

      it 'should set octavia provider ovn nb connection using unix socket' do
        is_expected.to contain_class('octavia::provider::ovn').with(:ovn_nb_connection => 'punix:/run/ovn/ovnnb_db.sock')
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end
      it_behaves_like 'tripleo::profile::base::octavia::provider::ovn'
    end
  end
end

