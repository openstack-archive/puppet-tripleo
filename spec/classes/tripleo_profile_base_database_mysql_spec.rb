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

describe 'tripleo::profile::base::database::mysql' do
  let :params do
    { :step                    => 2,
      :mysql_max_connections   => 4096,
    }
  end
  shared_examples_for 'tripleo::profile::base::database::mysql' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with noha and raise mariadb limit' do
      before do
        params.merge!({
          :generate_dropin_file_limit => true
        })
      end
      it 'should create limit file' do
        is_expected.to contain_systemd__service_limits('mariadb.service').with(
          :limits => { "LimitNOFILE" => 16384 })
      end
    end

    context 'with noha and do not raise mariadb limit' do
      before do
        params.merge!({
          :generate_dropin_file_limit => false
        })
      end
      it 'should not create limit file' do
        is_expected.to_not contain_systemd__service_limits('mariadb.service')
      end
    end

    context 'with ha and raise mariadb limit' do
      before do
        params.merge!({
          :generate_dropin_file_limit => true,
          :manage_resources => false,
        })
      end
      it 'should not create limit file in ha' do
        is_expected.to_not contain_systemd__service_limits('mariadb.service')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::database::mysql'
    end
  end
end
