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

describe 'tripleo::profile::base::neutron' do
  let :params do
    { :step => 5}
  end

  shared_examples_for 'tripleo::profile::base::neutron' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context "during deployment" do
      let(:facts) { super().merge({:current_neutron_host => ''})}
      it 'should set neutron::host to fqdn_canonical' do
        is_expected.to contain_class('neutron').with(:host => 'node.example.com')
      end
    end

    context 'during upgrade' do
      let(:facts) { super().merge({:heat_stack_action => '_update'})}
      context 'when current host is different from fqdn' do
        let(:facts) { super().merge({:current_neutron_host => 'node'})}
        it "should use the current_host" do
          is_expected.to contain_class('neutron').with(
                           :host => 'node',
                         )
        end
      end
      context 'when current neutron host cannot be found but nova host can' do
        let(:facts) { super().merge({:current_neutron_host => '',
                                     :current_nova_host    => 'node'})}
        it "should use the current_nova_host" do
          is_expected.to contain_class('neutron').with(
                           :host => 'node',
                         )
        end
      end
      context 'when both nova and neutron current host cannot be found' do
        let(:facts) { super().merge({:current_neutron_host => '',
                                     :current_nova_host    => '',
                                    })}
        it "fails" do
          is_expected.to compile.and_raise_error(/live value of the neutron/)
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
                      :hostname             => 'node.example.com',
                      :current_neutron_host => 'node.example.com'
                    })
      end

      it_behaves_like 'tripleo::profile::base::neutron'
    end
  end
end
