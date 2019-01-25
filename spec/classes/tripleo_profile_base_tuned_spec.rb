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

describe 'tripleo::profile::base::tuned' do

    shared_examples_for 'tripleo::profile::base::tuned' do
        context 'with profile' do
           let :params do
               {
                   :profile => 'virtual-compute'
               }
           end

            it 'should run tuned-adm exec' do
                is_expected.to contain_exec('tuned-adm')
            end
        end
        context 'with custom profile' do
           let :params do
               {
                   :profile => 'custom',
                   :custom_profile => 'foo'
               }
           end

            it 'should create a custom tuned profile' do
               is_expected.to contain_file('/etc/tuned/custom/tuned.conf').with({
                 'content' => 'foo',
                 'owner'   => 'root',
                 'group'   => 'root',
                 'mode'    => '0644',
                 })
            end
            it 'should run a tuned-adm exec to set the custom profile' do
               is_expected.to contain_exec('tuned-adm').with_command(
                 'tuned-adm profile custom'
               )
            end
        end
    end
    on_supported_os.each do |os, facts|
        context "on #{os}" do
            let(:facts) {
                facts
            }

        it_behaves_like 'tripleo::profile::base::tuned'
        end
    end
end
