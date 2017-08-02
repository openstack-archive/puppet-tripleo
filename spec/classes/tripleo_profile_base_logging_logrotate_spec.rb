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

describe 'tripleo::profile::base::logging::logrotate' do
  shared_examples_for 'tripleo::profile::base::logging::logrotate' do

    context 'with step less than 4' do
      let(:params) { { :step => 3 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::logging::logrotate')
        is_expected.to_not contain_cron('logrotate-crond')
        is_expected.to_not contain_file('/etc/logrotate-crond.conf')
      end
    end

    context 'with defaults and step greater than 3' do
      let(:params) { { :step => 4 } }

      it { is_expected.to contain_class('tripleo::profile::base::logging::logrotate') }
      it { is_expected.to contain_cron('logrotate-crond').with(
          :ensure   => 'present',
          :command  => 'sleep `expr ${RANDOM} \\% 90`; /usr/sbin/logrotate -s ' +
            '/var/lib/logrotate/logrotate-crond.status ' +
            '/etc/logrotate-crond.conf 2>&1|logger -t logrotate-crond',
          :user     => 'root',
          :minute   => 0,
          :hour     => '*',
          :monthday => '*',
          :month    => '*',
          :weekday  => '*') }
      it { is_expected.to contain_file('/etc/logrotate-crond.conf') }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::logging::logrotate'
    end
  end
end
