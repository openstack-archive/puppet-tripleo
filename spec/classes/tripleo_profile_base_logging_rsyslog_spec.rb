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
    tls.cacert="/etc/rsyslog.d/es-ca-cert.crt"
    tls.mycert="/etc/rsyslog.d/es-client-cert.pem"
    tls.myprivkey="/etc/rsyslog.d/es-client-key.pem"
  )
EOS

describe 'tripleo::profile::base::logging::rsyslog' do
  shared_examples_for 'tripleo::profile::base::logging::rsyslog' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'on step 2' do
      let(:params) do
        { :step => 2,
          :elasticsearch_tls_ca_cert => 'cacert',
          :elasticsearch_tls_client_cert => 'clientcert',
          :elasticsearch_tls_client_key => 'clientkey',
        }
      end

      it 'should generate a rsyslog config file for horizon from hieradata and TLS certificates for Elasticsearch' do
        should contain_concat__fragment('rsyslog::component::module::imfile').with({
          :target => '/etc/rsyslog.d/50_openstack_logs.conf',
          :content => "module(load=\"imfile\")\n",
        })
        should contain_concat__fragment('rsyslog::component::module::omelasticsearch').with({
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
        should contain_concat__fragment('rsyslog::component::action::elasticsearch').with({
          :target => '/etc/rsyslog.d/50_openstack_logs.conf',
          :content => elastic_conf,
        })
        should contain_file('elasticsearch_ca_cert').with({
          :path => '/etc/rsyslog.d/es-ca-cert.crt',
          :content => 'cacert',
        })
        should contain_file('elasticsearch_client_cert').with({
          :path => '/etc/rsyslog.d/es-client-cert.pem',
          :content => 'clientcert',
        })
        should contain_file('elasticsearch_client_key').with({
          :path => '/etc/rsyslog.d/es-client-key.pem',
          :content => 'clientkey',
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
