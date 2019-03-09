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

describe 'tripleo::profile::base::snmp' do

  shared_examples_for 'tripleo::profile::base::snmp' do
    context 'with default configuration' do
      let :params do
        {
          :snmpd_user     => 'ro_snmp_user',
          :snmpd_password => 'secrete',
          :step           => 4,
        }
      end

      it 'should configure snmpd' do
        is_expected.to contain_class('snmp').with(
          :snmpd_config => [
            'createUser ro_snmp_user MD5 "secrete"',
            'rouser ro_snmp_user',
            'proc  cron',
            'includeAllDisks  10%',
            'master agentx',
            'iquerySecName internalUser',
            'rouser internalUser',
            'defaultMonitors yes',
             'linkUpDownNotifications yes',
          ]
        )
      end
    end
    context 'with snmpd_config setting' do
      let :params do
        {
          :snmpd_user     => 'ro_snmp_user',
          :snmpd_password => 'secrete',
          :snmpd_config   => [
            'createUser ro_snmp_user MD5 "secrete"',
            'rouser ro_snmp_user',
            'proc  neutron-server',
          ],
          :step           => 4,
        }
      end

      it 'should configure snmpd with custom parameters' do
        is_expected.to contain_class('snmp').with(
          :snmpd_config => [
            'createUser ro_snmp_user MD5 "secrete"',
            'rouser ro_snmp_user',
            'proc  neutron-server',
          ]
        )
      end
    end
  end

    on_supported_os.each do |os, facts|
        context "on #{os}" do
            let(:facts) {
                facts
            }

        it_behaves_like 'tripleo::profile::base::snmp'
        end
    end
end
