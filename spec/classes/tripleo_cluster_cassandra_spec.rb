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
# Unit tests for the cassandra service

require 'spec_helper'

describe 'tripleo::cluster::cassandra' do

  shared_examples_for 'cassandra cluster service' do

    let :facts do
      {
        :hostname                  => 'host1.midonet',
        :osfamily                  => 'RedHat',
        :operatingsystemmajrelease => 7,
      }
    end

    let :params do
      {
        :cassandra_servers => ['192.168.2.2', '192.168.2.3'],
        :cassandra_ip      => '192.168.2.2'
      }
    end

    it 'should configure cassandra' do
      is_expected.to contain_class('cassandra').with(
        :seeds                      => ['192.168.2.2', '192.168.2.3'],
        :listen_address             => '192.168.2.2',
        :storage_port               => 7000,
        :ssl_storage_port           => 7001,
        :native_transport_port      => 9042,
        :rpc_port                   => 9160
      )

    end
  end

  it_configures 'cassandra cluster service'

end
