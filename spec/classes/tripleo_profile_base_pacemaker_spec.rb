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

describe 'tripleo::profile::base::pacemaker' do
  shared_examples_for 'tripleo::profile::base::pacemaker' do
    before :each do
      facts.merge!({
        :step => params[:step],
      })
    end

    context 'with step 4 with defaults (instanceha disabled)' do
      let(:params) { {
        :step => 4,
      } }

      it {
        is_expected.to_not contain_class('tripleo::profile::base::pacemaker::instance_ha')
        is_expected.to_not contain_class('pacemaker::stonith::fence_compute')
      }
    end

    context 'with step 4 with instanceha enabled' do
      let(:params) { {
        :step              => 4,
        :enable_instanceha => true,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::pacemaker::instance_ha')
        is_expected.to contain_class('pacemaker::resource_defaults')
        is_expected.to contain_pcmk_stonith('stonith-fence_compute-fence-nova').with({
          :stonith_type    => "fence_compute",
        })
        is_expected.to contain_pcmk_resource('compute-unfence-trigger').with({
          :resource_type   => "ocf:pacemaker:Dummy",
          :meta_params     => "requires=unfencing",
        })
        is_expected.to contain_pcmk_resource('nova-evacuate').with({
          :resource_type   => "ocf:openstack:NovaEvacuate",
          :resource_params => "auth_url=localhost:5000 username=admin password=password user_domain=Default project_domain=Default tenant_name=admin no_shared_storage=true",
        })
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::pacemaker'
    end
  end
end
