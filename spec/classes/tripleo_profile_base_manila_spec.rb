#
# Copyright (C) 2019 Red Hat, Inc.
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

describe 'tripleo::profile::base::manila' do
  shared_examples_for 'tripleo::profile::base::manila' do
    context 'with step less than 3' do
      let(:params) { {
        :step                    => 1,
        :bootstrap_node          => 'node.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'manila1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'manila2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to_not contain_class('manila')
        is_expected.to_not contain_class('manila::config')
        is_expected.to_not contain_class('manila::logging')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step                    => 3,
        :bootstrap_node          => 'node.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'manila1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'manila2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to contain_class('manila').with(
          :default_transport_url      => 'rabbit://manila1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://manila2:baa@192.168.0.2:5678/?ssl=0'
        )
        is_expected.to contain_class('manila::config')
        is_expected.to contain_class('manila::logging')
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step                    => 3,
        :bootstrap_node          => 'note.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'manila1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'manila2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to_not contain_class('manila')
        is_expected.to_not contain_class('manila::config')
        is_expected.to_not contain_class('manila::logging')
      }
    end

    context 'with step 4' do
      let(:params) { {
        :step                    => 4,
        :bootstrap_node          => 'other.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'manila1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'manila2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::manila')
        is_expected.to contain_class('manila').with(
          :default_transport_url      => 'rabbit://manila1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://manila2:baa@192.168.0.2:5678/?ssl=0'
        )
        is_expected.to contain_class('manila::config')
        is_expected.to contain_class('manila::logging')
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::manila'
    end
  end
end
