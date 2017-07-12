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

describe 'tripleo::profile::base::aide' do

  shared_examples_for 'tripleo::profile::base::aide' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 5' do
      let(:params) { { :step => 1 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::aide')
        is_expected.to_not contain_class('tripleo::profile::base::aide::cron')
        is_expected.to_not contain_class('tripleo::profile::base::aide::rules')
        is_expected.to_not contain_class('tripleo::profile::base::aide::installdb')
      end
    end

    context 'with step greater of 5' do
      let(:params) { {
          :step => 5
      } }

      it 'should configure aide' do
        is_expected.to contain_class('tripleo::profile::base::aide')
        is_expected.to contain_class('tripleo::profile::base::aide::cron')
        is_expected.to contain_class('tripleo::profile::base::aide::installdb')
        is_expected.to_not contain_class('tripleo::profile::base::aide::rules')
      end

      it 'should concat aide.conf' do
        is_expected.to contain_concat('aide.conf').with({
           "ensure" => "present",
           "ensure_newline" => "true",
           "owner"=>"root",
           "group"=>"root",
           "mode"=>"0600"})
      end

      it 'should concat fragment aide.conf' do
        should contain_concat__fragment('aide.conf.header').with({
          :target => 'aide.conf'
        })
      end

      it 'should initiate aide database' do
        should contain_exec('aide init').with({
          :command => "aide --init --config /etc/aide.conf"
       })
      end

      it 'should set new database to main database' do
        should contain_exec('install aide db').with({
          :command => "cp -f /var/lib/aide/aide.db.new /var/lib/aide/aide.db"
       })
      end

      it 'should contain database file' do
        should contain_file('/var/lib/aide/aide.db').with({
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0600'
       })
      end

      it 'should configure cron' do
        should contain_cron('aide').with({
          :user => 'root',
          :hour => 3,
          :minute => 0
        })
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
        it_behaves_like 'tripleo::profile::base::aide'
    end
  end
end
