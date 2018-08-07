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
        :servername               => facts[:hostname],
        :bind_host                => '127.0.0.1',
        :endpoint_proxy_keystone  => 'http://127.0.0.1:5000',
        :endpoint_proxy_zaqar     => 'ws://127.0.0.1:9000/zaqar',
        :endpoint_proxy_heat      => 'http://127.0.0.1:8004',
        :endpoint_proxy_ironic    => 'http://127.0.0.1:6385',
        :endpoint_proxy_mistral   => 'http://127.0.0.1:8989',
        :endpoint_proxy_swift     => 'http://127.0.0.1:8080',
        :endpoint_config_keystone => 'https://127.0.0.1:443/keystone/v2.0',
        :endpoint_config_zaqar    => 'wss://127.0.0.1:443/zaqar',
        :endpoint_config_heat     => 'https://127.0.0.1:443/heat/v1/%(tenant_id)s',
        :endpoint_config_ironic   => 'https://127.0.0.1:443/ironic',
        :endpoint_config_mistral  => 'https://127.0.0.1:443/mistral/v2',
        :endpoint_config_swift    => 'https://127.0.0.1:443/swift/v1/AUTH_%(tenant_id)s'
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
          :fallbackresource => '/index.html',
          :directories      => [
            {
              "path"            => '/var/www/openstack-tripleo-ui/dist',
              "provider"        => 'directory',
              "options"         => ['Indexes', 'FollowSymLinks'],
              "expires_active"  => 'On',
              "expires_by_type" => [
                'text/javascript "access plus 1 months"'
              ]
            }
          ]
        )
        is_expected.to contain_file('/etc/httpd/conf.d/openstack-tripleo-ui.conf')
            .with_content(/cleaned by Puppet/)
        is_expected.to contain_file('/var/www/openstack-tripleo-ui/dist/tripleo_ui_config.js')
            .with_content(/'keystone': 'https:\/\/127.0.0.1:443\/keystone\/v2.0'/)
            .with_content(/'heat': 'https:\/\/127.0.0.1:443\/heat\/v1\/%\(tenant_id\)s'/)
            .with_content(/'zaqar-websocket': 'wss:\/\/127.0.0.1:443\/zaqar'/)
            .with_content(/'ironic': 'https:\/\/127.0.0.1:443\/ironic'/)
            .with_content(/'mistral': 'https:\/\/127.0.0.1:443\/mistral\/v2'/)
            .with_content(/'swift': 'https:\/\/127.0.0.1:443\/swift\/v1\/AUTH_%\(tenant_id\)s'/)
            .with_content(/'zaqar_default_queue': 'tripleo'/)
      end
    end

    context 'with all parameters' do
      let(:params) { {
          :servername             => 'custom.example.com',
        :bind_host                => '127.0.0.2',
        :ui_port                  => 3001,
        :endpoint_proxy_keystone  => 'http://127.0.0.1:5000',
        :endpoint_proxy_zaqar     => 'ws://127.0.0.1:9000/zaqar',
        :endpoint_proxy_heat      => 'http://127.0.0.1:8004',
        :endpoint_proxy_ironic    => 'http://127.0.0.1:6385',
        :endpoint_proxy_mistral   => 'http://127.0.0.1:8989',
        :endpoint_proxy_swift     => 'http://127.0.0.1:8080',
        :endpoint_config_keystone => 'https://127.0.0.1:443/keystone/v2.0',
        :endpoint_config_zaqar    => 'wss://127.0.0.1:443/zaqar',
        :endpoint_config_heat     => 'https://127.0.0.1:443/heat/v1/%(tenant_id)s',
        :endpoint_config_ironic   => 'https://127.0.0.1:443/ironic',
        :endpoint_config_mistral  => 'https://127.0.0.1:443/mistral/v2',
        :endpoint_config_swift    => 'https://127.0.0.1:443/swift/v1/AUTH_%(tenant_id)s',
        :zaqar_default_queue      => 'tripleo'
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
          .with_content(/'keystone': 'https:\/\/127.0.0.1:443\/keystone\/v2.0'/)
          .with_content(/'heat': 'https:\/\/127.0.0.1:443\/heat\/v1\/%\(tenant_id\)s'/)
          .with_content(/'zaqar-websocket': 'wss:\/\/127.0.0.1:443\/zaqar'/)
          .with_content(/'ironic': 'https:\/\/127.0.0.1:443\/ironic'/)
          .with_content(/'mistral': 'https:\/\/127.0.0.1:443\/mistral\/v2'/)
          .with_content(/'swift': 'https:\/\/127.0.0.1:443\/swift\/v1\/AUTH_%\(tenant_id\)s'/)
          .with_content(/'zaqar_default_queue': 'tripleo'/)
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
