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

describe 'tripleo::haproxy::stats' do

  shared_examples_for 'tripleo::haproxy::stats' do
    let :pre_condition do
      "Haproxy::Listen {
        config_file => '/etc/haproxy.cfg'
      }"
    end

    context 'with only required parameters' do
      let(:params) do
        {
          :ip => '127.0.0.1',
          :haproxy_listen_bind_param => ['transparent'],
        }
      end
      it 'should configure basic stats frontend' do
        is_expected.to contain_haproxy__listen('haproxy.stats').with(
          :bind => {
            "127.0.0.1:1993" => ['transparent']
          },
          :mode => 'http',
          :options => {
            'stats' => ['enable', 'uri /']
          },
          :collect_exported => false
        )
      end
    end

    context 'with auth parameters' do
      let(:params) do
        {
          :ip                        => '127.0.0.1',
          :haproxy_listen_bind_param => ['transparent'],
          :user                      => 'myuser',
          :password                  => 'superdupersecret',
        }
      end
      it 'should configure stats frontend with auth enabled' do
        is_expected.to contain_haproxy__listen('haproxy.stats').with(
          :bind => {
            "127.0.0.1:1993" => ['transparent']
          },
          :mode => 'http',
          :options => {
            'stats' => ['enable', 'uri /', 'auth myuser:superdupersecret']
          },
          :collect_exported => false
        )
      end
    end

    context 'with certificate parameter' do
      let(:params) do
        {
          :ip                        => '127.0.0.1',
          :haproxy_listen_bind_param => ['transparent'],
          :certificate               => '/path/to/cert',
        }
      end
      it 'should configure stats frontend with TLS enabled' do
        is_expected.to contain_haproxy__listen('haproxy.stats').with(
          :bind => {
            "127.0.0.1:1993" => ['transparent', 'ssl', 'crt', '/path/to/cert']
          },
          :mode => 'http',
          :options => {
            'stats' => ['enable', 'uri /']
          },
          :collect_exported => false
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::haproxy::stats'
    end
  end
end
