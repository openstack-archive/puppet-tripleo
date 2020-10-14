# coding: utf-8
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

describe 'tripleo::profile::base::lvm' do

  shared_examples_for 'tripleo::profile::base::lvm' do

    context 'with default params' do
      it 'should enable udev_sync and udev_rules' do
        is_expected.to contain_augeas('udev options in lvm.conf')
          .with_changes(["set udev_sync/int 1",
                         "set udev_rules/int 1"])
      end
    end

    context 'with enable_udev false' do
      let(:params) { { :enable_udev => false } }

      it 'should disable udev_sync and udev_rules' do
        is_expected.to contain_augeas('udev options in lvm.conf')
          .with_changes(["set udev_sync/int 0",
                         "set udev_rules/int 0"])
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::lvm'
    end
  end
end
