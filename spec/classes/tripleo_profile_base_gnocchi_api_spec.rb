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

describe 'tripleo::profile::base::gnocchi::api' do
  shared_examples_for 'tripleo::profile::base::gnocchi::api' do
    let(:pre_condition) do
      "class { '::tripleo::profile::base::gnocchi': step => #{params[:step]}, }"
    end

    context 'with step less than 3' do
      let(:params) { { :step => 2 } }

      it {
        is_expected.to contain_class('tripleo::profile::base::gnocchi::api')
        is_expected.to_not contain_class('gnocchi::api')
        is_expected.to_not contain_class('gnocchi::wsgi::apache')
      }
    end

    context 'with step 3 on bootstrap' do
      let(:params) { {
        :step => 3,
        :bootstrap_node => 'node.example.com',
      } }

      it {
        is_expected.to contain_class('gnocchi::db::sync')
        is_expected.to contain_class('gnocchi::api')
        is_expected.to contain_class('gnocchi::wsgi::apache')
      }
    end

    context 'with step 3' do
      let(:params) { {
        :step => 3,
      } }

      it {
        is_expected.to_not contain_class('gnocchi::db::sync')
        is_expected.to contain_class('gnocchi::api')
        is_expected.to contain_class('gnocchi::wsgi::apache')
      }
    end

    # TODO(aschultz): fix profile class to not include hiera look ups in the
    # step 4 so we can properly test it
    #context 'with step 4' do
    #  let(:params) { {
    #    :step            => 4,
    #  } }
    #
    #  it {
    #    is_expected.to contain_class('gnocchi::api')
    #    is_expected.to contain_class('gnocchi::wsgi::apache')
    #    is_expected.to contain_class('gnocchi::storage')
    #  }
    #end
    #
    #context 'with step 5 on bootstrap' do
    #  let(:params) { {
    #    :step => 5,
    #    :bootstrap_node => 'node.example.com'
    #  } }
    #
    #  it {
    #    is_expected.to contain_class('gnocchi::api')
    #    is_expected.to contain_class('gnocchi::wsgi::apache')
    #    is_expected.to contain_exec('run gnocchi upgrade with storage').with(
    #      :command => 'gnocchi-upgrade --config-file=/etc/gnocchi/gnocchi.conf',
    #      :path    => ['/usr/bin', '/usr/sbin']
    #    )
    #  }
    #end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::gnocchi::api'
    end
  end
end
