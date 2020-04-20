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

describe 'tripleo::profile::base::gnocchi::metricd' do

  before :each do
    facts.merge!({ :step => params[:step] })
  end

  shared_examples_for 'tripleo::profile::base::gnocchi::metricd' do
    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::gnocchi':
        step => #{params[:step]},
      }
eos
    end

    context 'with step less than 5' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::gnocchi::metricd')
        is_expected.to contain_class('tripleo::profile::base::gnocchi')
        is_expected.to_not contain_class('gnocchi::metricd')
      }
    end

    context 'with step 5' do
      let(:params) { {
        :step => 5,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::gnocchi::metricd')
        is_expected.to contain_class('tripleo::profile::base::gnocchi')
        is_expected.to contain_class('gnocchi::metricd')
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::gnocchi::metricd'
    end
  end
end
