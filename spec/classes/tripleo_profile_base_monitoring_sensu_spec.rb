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

describe 'tripleo::profile::base::monitoring::sensu' do
  shared_examples_for 'tripleo::profile::base::monitoring::sensu' do

    context 'Sensu' do
      let (:params) { { :step => 3 } }
      it { is_expected.to contain_class('sensu') }
      it { is_expected.to contain_package('osops-tools-monitoring-oschecks') }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts.merge({ :ipaddress => '127.0.0.1' })
      }
      it_behaves_like 'tripleo::profile::base::monitoring::sensu'
    end
  end

end
