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

describe 'tripleo::haproxy' do

  shared_examples_for 'tripleo::haproxy' do
    let :params do {
      :controller_virtual_ip     => '10.1.0.1',
      :public_virtual_ip         => '192.168.0.1'
    }
    end

    describe "default settings" do
      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'timeout client' => "90m",
            'timeout server' => "90m",
            'maxconn'        => :undef
          }
        )
      end
    end

    describe "set clustercheck" do
      before :each do
        params.merge!({
          :mysql_clustercheck => true,
        })
      end

      it 'should configure haproxy with clustercheck' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'timeout client' => "90m",
            'timeout server' => "90m",
            'option'         => ["tcpka", "httpchk"],
            'timeout client' => "90m",
            'timeout server' => "90m",
            'stick-table'    => "type ip size 1000",
            'stick'          => "on dst",
            'maxconn'        => :undef
          }
        )
      end
    end

    describe "override maxconn with clustercheck" do
      before :each do
        params.merge!({
          :mysql_clustercheck  => true,
          :mysql_max_conn      => 6500,
        })
      end

      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'option'         => ["tcpka", "httpchk"],
            'timeout client' => "90m",
            'timeout server' => "90m",
            'stick-table'    => "type ip size 1000",
            'stick'          => "on dst",
            'maxconn'        => 6500
          }
        )
      end
    end

    describe "horizon" do
      before :each do
        params.merge!({
          :horizon      => true,
        })
      end

      it 'should configure haproxy horizon endpoint' do
        is_expected.to contain_class('tripleo::haproxy::horizon_endpoint')
        is_expected.to contain_haproxy__balancermember('horizon_127.0.0.1_controller-1').with(
          :options => ['check', 'inter 2000', 'rise 2', 'fall 5', 'cookie controller-1'],
        )
      end
    end

    describe "override maxconn without clustercheck" do
      before :each do
        params.merge!({
          :mysql_max_conn => 6500,
        })
      end

      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'timeout client' => "90m",
            'timeout server' => "90m",
            'maxconn'        => 6500
          }
        )
      end
    end

    describe "default Defaults for haproxy" do
      it 'should NOT activate httplog' do
        is_expected.to contain_class('haproxy').with(
          :defaults_options => {
            "mode"=>"tcp",
            "log"=>"global",
            "retries"=>"3",
            "timeout"=> [
              "http-request 10s",
              "queue 2m",
              "connect 10s",
              "client 2m",
              "server 2m",
              "check 10s",
            ],
            "maxconn"=>4096,
          }
        )
      end
    end

    describe "activate httplog" do
      before :each do
        params.merge!({
          :activate_httplog => true,
        })
      end
      it 'should activate httplog' do
        is_expected.to contain_class('haproxy').with(
          :defaults_options => {
            "mode"=>"tcp",
            "log"=>"global",
            "retries"=>"3",
            "timeout"=> [
              "http-request 10s",
              "queue 2m",
              "connect 10s",
              "client 2m",
              "server 2m",
              "check 10s",
            ],
            "maxconn"=>4096,
            "option"=>"httplog",
          }
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ })
      end

      it_behaves_like 'tripleo::haproxy'
    end
  end

end
