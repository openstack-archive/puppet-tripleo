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

describe 'tripleo::ui' do
  shared_examples_for 'tripleo::ui' do
    let(:pre_condition) do
      'include ::apache'
    end

    context 'with required parameters' do
      let(:params) { {
        :servername   => facts[:hostname],
        :bind_host    => '127.0.0.1',
        :keystone_url => 'http://127.0.0.1:5000/'
      } }

      it 'should configure tripleo ui' do
        is_expected.to contain_class('tripleo::ui')
        is_expected.to contain_apache__vhost('tripleo-ui').with(
          :ensure           => 'present',
          :servername       => facts[:hostname],
          :ip               => '127.0.0.1',
          :port             => 3000,
          :docroot          => '/var/www/openstack-tripleo-ui/dist',
          :options          => [ 'Indexes', 'FollowSymLinks' ],
          :fallbackresource => '/index.html'
        )
        is_expected.to contain_file('/etc/httpd/conf.d/openstack-tripleo-ui.conf').with_content(/cleaned by Puppet/)
        is_expected.to contain_file('/var/www/openstack-tripleo-ui/dist/tripleo_ui_config.js')
            .with_content(/"keystone": "http:\/\/127.0.0.1:5000\/"/)
            .with_content(/"zaqar_default_queue": "tripleo"/)
      end
    end

    context 'with all parameters' do
      let(:params) { {
          :servername        => 'custom.example.com',
        :bind_host           => '127.0.0.2',
        :ui_port             => 3001,
        :keystone_url        => 'http://127.0.0.1:1111/',
        :heat_url            => 'http://127.0.0.1:2222/',
        :ironic_url          => 'http://127.0.0.1:3333/',
        :mistral_url         => 'http://127.0.0.1:4444/',
        :swift_url           => 'http://127.0.0.1:5555/',
        :zaqar_websocket_url => 'http://127.0.0.1:6666/',
        :zaqar_default_queue => 'myqueue'
      } }

      it 'should configure tripleo ui' do
        is_expected.to contain_class('tripleo::ui')
        is_expected.to contain_apache__vhost('tripleo-ui').with(
          :ensure           => 'present',
          :servername       => 'custom.example.com',
          :ip               => '127.0.0.2',
          :port             => 3001,
          :docroot          => '/var/www/openstack-tripleo-ui/dist',
          :options          => [ 'Indexes', 'FollowSymLinks' ],
          :fallbackresource => '/index.html'
        )
        is_expected.to contain_file('/etc/httpd/conf.d/openstack-tripleo-ui.conf').with_content(/cleaned by Puppet/)
        is_expected.to contain_file('/var/www/openstack-tripleo-ui/dist/tripleo_ui_config.js')
            .with_content(/"keystone": "http:\/\/127.0.0.1:1111\/"/)
            .with_content(/"heat": "http:\/\/127.0.0.1:2222\/"/)
            .with_content(/"ironic": "http:\/\/127.0.0.1:3333\/"/)
            .with_content(/"mistral": "http:\/\/127.0.0.1:4444\/"/)
            .with_content(/"swift": "http:\/\/127.0.0.1:5555\/"/)
            .with_content(/"zaqar-websocket": "http:\/\/127.0.0.1:6666\/"/)
            .with_content(/"zaqar_default_queue": "myqueue"/)
      end
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::ui'
    end
  end
end
