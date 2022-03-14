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

describe 'tripleo::profile::base::qdr' do

  let :params do
    {
      :step => 3,
      :qdr_username   => 'openstack',
      :qdr_password   => 'bigsecret',
    }
  end

  shared_examples_for 'tripleo::profile::base::qdr' do

    context 'with step 3 on single node' do
      before do
        facts.merge!({
          :hostname => 'node.example.com',
        })
        params.merge!({
          :oslomsg_rpc_hosts => ['node.example.com'],
        })
      end

      it 'should setup standalone' do
        is_expected.to contain_class('qdr').with(
          :router_mode     => 'standalone',
          :extra_listeners => [],
          :connectors => [],
        )
      end
    end

    context 'with step 3 on node1 of multinode' do
      before do
        facts.merge!({
          :hostname => 'node1.example.com',
        })
        params.merge!({
          :oslomsg_rpc_hosts => ['node1.example.com','node2.example.com','node3.example.com'],
        })
      end

      it 'should set interior listener and no connectors' do
        is_expected.to contain_class('qdr').with(
          :router_mode     => 'interior',
          :extra_listeners => [{'host' => '0.0.0.0','port' => '31460','role' => 'inter-router'}],
          :connectors => [],
        )
      end
    end

    context 'with step 3 on node2 of multinode' do
      before do
        facts.merge!({
          :hostname => 'node2.example.com',
        })
        params.merge!({
          :oslomsg_rpc_hosts => ['node1.example.com','node2.example.com','node3.example.com'],
        })
      end

      it 'should set up interior listener and one connector' do
        is_expected.to contain_class('qdr').with(
          :router_mode     => 'interior',
          :extra_listeners => [{'host' => '0.0.0.0','port' => '31460','role' => 'inter-router'}],
          :connectors => [{"host"=>"node1.example.com", "role"=>"inter-router", "port"=>"31460"}],
        )
      end
    end

    context 'with step 3 on node3 of multinode' do
      before do
        facts.merge!({
          :hostname => 'node3.example.com',
        })
        params.merge!({
          :oslomsg_rpc_hosts => ['node1.example.com','node2.example.com','node3.example.com'],
        })
      end

      it 'should set up interior listener and two connectors' do
        is_expected.to contain_class('qdr').with(
          :router_mode     => 'interior',
          :extra_listeners => [{'host' => '0.0.0.0','port' => '31460','role' => 'inter-router'}],
          :connectors => [
            {"host"=>"node1.example.com", "role"=>"inter-router", "port"=>"31460"},
            {"host"=>"node2.example.com", "role"=>"inter-router", "port"=>"31460"}],
        )
      end
    end

    context 'with step 3 on node3 of multinode with ssl' do
      before do
        facts.merge!({
          :hostname => 'node3.example.com',
          :fqdn     => 'node3.example.com',
        })
        params.merge!({
          :oslomsg_rpc_hosts => ['node1.example.com','node2.example.com','node3.example.com'],
          :listener_require_ssl => 'yes',
        })
      end

      it 'should set up interior listener with sslProfile and two connectors with sslProfile' do
        is_expected.to contain_class('qdr').with(
          # this should be true instead of 'yes', because 'yes' is deprecated,
          # but until we have rspec-puppet >= 2.7.9 to get:
          #
          # https://github.com/rodjek/rspec-puppet/commit/5e6b5e40dd22c5db5a8c7d8f21597d8ba95b1ddc
          #
          # Then it will throw a FrozenError.  So just test with 'yes' instead.
          :listener_require_ssl => 'yes',
          :router_mode     => 'interior',
          :extra_listeners => [{'sslProfile' => 'Router.node3.example.com',
                                'host'       => '0.0.0.0',
                                'port'       => '31460',
                                'role'       => 'inter-router'}],
          :connectors => [
            {"sslProfile" => "Router.node3.example.com",
             "host"       => "node1.example.com",
             "role"       => "inter-router",
             "port"       => "31460"},
            {"sslProfile" => "Router.node3.example.com",
             "host"       => "node2.example.com",
             "role"       => "inter-router",
             "port"       => "31460"}],
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::qdr'
    end
  end
end
