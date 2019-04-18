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

describe 'tripleo::profile::base::placement::api' do
  shared_examples_for 'tripleo::profile::base::placement::api' do
    let(:pre_condition) do
      <<-eos
      class { '::tripleo::profile::base::placement':
        step => #{params[:step]},
      }
      class { '::tripleo::profile::base::placement::authtoken':
        step     => #{params[:step]},
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::placement::api')
        is_expected.to_not contain_class('placement::keystone::authtoken')
        is_expected.to_not contain_class('placement::wsgi::apache')
      }
    end

    context 'with step less than 3 and internal tls and generate certs' do
      let(:params) { {
        :step                          => 1,
        :enable_internal_tls           => true,
        :placement_network             => 'bar',
        :certificates_specs            => {
            'httpd-bar' => {
                'hostname'            => 'foo',
                'service_certificate' => '/foo.pem',
                'service_key'         => '/foo.key',
            },
        }
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::placement::api')
        is_expected.to_not contain_class('placement::keystone::authtoken')
        is_expected.to_not contain_class('placement::wsgi::apache')
      }
    end

    context 'with step 3 and not bootstrap' do
      let(:params) { {
        :step => 3,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::placement::api')
        is_expected.to contain_class('placement::keystone::authtoken')
        is_expected.not_to contain_class('placement::wsgi::apache')
      }
    end

    context 'with step 3 and bootstrap' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::placement::api')
        is_expected.to contain_class('placement::keystone::authtoken')
        is_expected.to contain_class('placement::wsgi::apache')
      }
    end

    context 'with step 3 and bootstrap with enable_internal_tls and skip generate certs' do
      let(:params) { {
        :step => 3,
        :enable_internal_tls           => true,
        :placement_network             => 'bar',
        :bootstrap_node                => 'node.example.com',
        :certificates_specs            => {
            'httpd-bar' => {
                 'hostname'           => 'foo',
                'service_certificate' => '/foo.pem',
                'service_key'         => '/foo.key',
            },
        }

      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::placement::api')
        is_expected.to contain_class('placement::keystone::authtoken')
        is_expected.to contain_class('placement::wsgi::apache').with(
          :ssl_cert => '/foo.pem',
          :ssl_key  => '/foo.key')
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::placement::api'
    end
  end
end
