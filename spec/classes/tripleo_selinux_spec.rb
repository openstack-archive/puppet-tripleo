# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
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
# Unit tests for tripleo::selinux
#

require 'spec_helper'

describe 'tripleo::selinux' do

  shared_examples_for 'tripleo::selinux' do

    context 'sebool and semodule management' do
      before :each do
        facts.merge!({
          :selinux              => true,
          :selinux_current_mode => 'enforcing'
        })
      end

      let :params do
        { :booleans   => ['foo', 'bar'],
          :modules    => ['module1', 'module2'],
          :directory  => '/path/to/modules'}
      end

      it 'enables the SELinux boolean' do
        is_expected.to contain_selboolean('foo').with(
          :persistent => true,
          :value      => 'on',
        )
      end

      it 'enables the SELinux modules' do
        is_expected.to contain_selmodule('module1').with(
          :ensure       => 'present',
          :selmoduledir => '/path/to/modules',
        )
      end

    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_raises 'a Puppet::Error', /OS family unsuppored yet \(Debian\), SELinux support is only limited to RedHat family OS/
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::selinux'
    end
  end
end
