#
# Copyright (C) 2015 Midokura SARL
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
# Unit tests for the midonet api

require 'spec_helper'

describe 'tripleo::network::midonet::api' do

  let :facts do
    {
      :augeasversion => '1.0.0'
    }
  end

  shared_examples_for 'midonet api test' do

    let :params do
      {
        :zookeeper_servers    => ['192.168.2.1', '192.168.2.2'],
        :vip                  => '192.23.0.2',
        :keystone_ip          => '192.23.0.2',
        :keystone_admin_token => 'admin_token',
        :admin_password       => 'admin_password',
        :bind_address         => '192.23.0.65'
      }
    end

    it 'should call api configuration' do
      is_expected.to contain_class('midonet::midonet_api::run').with(
        :zk_servers                => [{'ip' => '192.168.2.1', 'port' => 2181},
                                       {'ip' => '192.168.2.2', 'port' => 2181}],
        :keystone_auth             => true,
        :tomcat_package            => 'tomcat',
        :vtep                      => false,
        :api_ip                    => '192.23.0.2',
        :api_port                  => '8081',
        :keystone_host             => '192.23.0.2',
        :keystone_port             => 35357,
        :keystone_admin_token      => 'admin_token',
        :keystone_tenant_name      => 'admin',
        :catalina_base             => '/usr/share/tomcat',
        :bind_address              => '192.23.0.65'
      )
    end

    it 'should install the cli' do
      is_expected.to contain_class('midonet::midonet_cli').with(
        :api_endpoint => 'http://192.23.0.2:8081/midonet-api',
        :username     => 'admin',
        :password     => 'admin_password',
        :tenant_name  => 'admin'
      )
    end

  end

  it_configures 'midonet api test'

end
