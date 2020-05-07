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

sensubility_conf = "
[default]

[sensu]
connection=ampq://sensu:sensu@localhost:5672//sensu
subscriptions=default,test
checks={\"standalone_check\":{\"command\":\"echo 'foobar'\",\"interval\":5}}

[amqp1]
"
exec_cmd = <<-EOS
  Exec \"collectd:collectd\" \"collectd-sensubility\"
EOS


describe 'tripleo::profile::base::metrics::collectd' do
  shared_examples_for 'tripleo::profile::base::metrics::collectd' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 3' do
      let(:params) { { :step => 2, :gnocchi_server => 'localhost' } }
      it 'should do nothing' do
        is_expected.to_not contain_class('collectd')
      end
    end

    context 'with defaults and step greater than 3, gnocchi deploy' do
      let(:params) { { :step => 3, :gnocchi_server => 'localhost' } }
      it 'has collectd class with gnocchi plugin and python plugin' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_class('collectd').with(
          :manage_repo => false,
        )
        is_expected.to contain_service('collectd').with(
          :ensure => 'running',
          :enable => true,
        )
        is_expected.to contain_package('python-collectd-gnocchi').with(
          :ensure => 'present',
        )
        is_expected.to_not contain_class('epel')
        is_expected.to_not contain_class('collectd::plugin::amqp1')
        is_expected.to_not contain_class('collectd::plugin::logfile')
      end
    end

    context 'with enabled file_logging and step greater than 3' do
      let(:params) do
        { :step => 3,
          :enable_file_logging => true,
          :gnocchi_server => 'localhost' }
      end
      it 'Contains both' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_class('collectd')
        is_expected.to contain_class('collectd::plugin::logfile')
      end
    end

    context 'with defaults and step greater than 3, amqp deploy' do
      let(:params) do
          { :step => 3,
            :amqp_host => 'localhost',
          }
      end

      it 'has amqp class' do
       is_expected.to compile.with_all_deps
       is_expected.to contain_class('collectd')
       is_expected.to contain_class('collectd::plugin::amqp1').with(
         :manage_package => true,
       )
       is_expected.to contain_service('collectd').with(
         :ensure => 'running',
         :enable => true,
       )
      end
    end

    context 'with defaults and enabled sensubility' do
      let(:params) do
        { :step => 3,
          :amqp_host => 'localhost',
          :enable_sensubility => true }
      end
      it 'has collectd class with exec plugin and enabled sensubility' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_package('collectd-sensubility').with(:ensure => 'present')
        is_expected.to contain_class('collectd')
        is_expected.to contain_class('collectd::plugin::exec')
        is_expected.to contain_concat__fragment('collectd_plugin_exec_conf_sensubility').with({
          :order => 50,
          :target => '/etc/collectd.d/exec-config.conf',
          :content => exec_cmd,
        })
        is_expected.to contain_file('/etc/collectd-sensubility.conf').with_content(sensubility_conf)
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::metrics::collectd'
    end
  end
end
