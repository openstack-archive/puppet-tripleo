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

horizon_access_log_conf = <<-EOS
# horizon_openstack.horizon.access
input(type="imfile"
  file="/var/log/horizon/access.log"
  tag="openstack.horizon.access"
  startmsg.regex="^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+ [0-9]+)? (DEBUG|INFO|WARNING|ERROR) "
)
EOS
horizon_test_log_conf = <<-EOS
# horizon_openstack.horizon.test
input(type="imfile"
  file="/var/log/horizon/test.log"
  tag="openstack.horizon.test"
  startmsg.regex="^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+ [0-9]+)? (DEBUG|INFO|WARNING|ERROR) "
)
EOS
elastic_conf = <<-EOS
# elasticsearch
action(type="omelasticsearch"
    name="elasticsearch"
)
EOS

describe 'tripleo::profile::base::logging::rsyslog' do
  shared_examples_for 'tripleo::profile::base::logging::rsyslog' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'on step 2' do
      let(:params) { { :step => 2 } }

      it 'should generate a rsyslog config file for horizon from hieradata' do
        should contain_concat__fragment("rsyslog::component::module::imfile").with({
          :target => '/etc/rsyslog.d/50_openstack_logs.conf',
          :content => "module(load=\"imfile\")\n",
        })
        should contain_concat__fragment("rsyslog::component::module::omelasticsearch").with({
          :target => '/etc/rsyslog.d/50_openstack_logs.conf',
          :content => "module(load=\"omelasticsearch\")\n",
        })
        should contain_concat__fragment('rsyslog::component::input::horizon_openstack.horizon.access').with({
          :target => '/etc/rsyslog.d/50_openstack_logs.conf',
          :content => horizon_access_log_conf,
        })
        should contain_concat__fragment('rsyslog::component::input::horizon_openstack.horizon.test').with({
          :target => '/etc/rsyslog.d/50_openstack_logs.conf',
          :content => horizon_test_log_conf,
        })
        should contain_concat__fragment("rsyslog::component::action::elasticsearch").with({
          :target => '/etc/rsyslog.d/50_openstack_logs.conf',
          :content => elastic_conf,
        })
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::logging::rsyslog'
    end
  end
end
