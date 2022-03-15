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

describe 'tripleo::profile::base::ceilometer::agent::notification' do
  shared_examples_for 'tripleo::profile::base::ceilometer::agent::notification' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) do
        { :step => 3 }
      end

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer::agent::notification')
        is_expected.to contain_class('tripleo::profile::base::ceilometer::upgrade')
        is_expected.to_not contain_class('ceilometer::agent::service_credentials')
        is_expected.to_not contain_class('ceilometer::agent::notification')
      end
    end

    context 'with step 4 and notifier configured' do
      let(:params) do
        { :step                      => 4,
          :notifier_enabled          => false,
          :notifier_events_enabled   => true,
          :notifier_host_addr        => '127.0.0.1',
          :notifier_host_port        => '5666' }
      end

      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer::agent::notification')
        is_expected.to contain_class('tripleo::profile::base::ceilometer::upgrade')
        is_expected.to contain_class('ceilometer::agent::service_credentials')
        is_expected.to contain_class('ceilometer::agent::notification').with(
          :event_pipeline_publishers => ["notifier://127.0.0.1:5666/?driver=amqp&topic=ceilometer/event.sample"],
          :pipeline_publishers => []
        )
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::ceilometer::agent::notification'
    end
  end
end
