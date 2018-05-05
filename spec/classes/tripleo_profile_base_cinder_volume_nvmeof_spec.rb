require 'spec_helper'

describe 'tripleo::profile::base::cinder::volume::nvmeof' do
  shared_examples_for 'tripleo::profile::base::cinder::volume::nvmeof' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :target_ip_address => '127.0.0.1',
        :target_port       => '4420',
        :target_helper     => 'nvmet',
        :target_protocol   => 'nvmet_rdma',
        :step => 3
      } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume::nvmeof')
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_class('cinder::setup_test_volume')
        is_expected.to_not contain_cinder__backend__nvmeof('tripleo_nvmeof')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :target_ip_address => '127.0.0.1',
        :target_port       => '4420',
        :target_helper     => 'nvmet',
        :target_protocol   => 'nvmet_rdma',
        :step => 4,
      } }

      context 'with defaults' do
        it 'should trigger complete configuration' do
          is_expected.to contain_cinder__backend__nvmeof('tripleo_nvmeof').with(
            :target_ip_address => '127.0.0.1',
            :target_port       => '4420',
            :target_helper     => 'nvmet',
            :target_protocol   => 'nvmet_rdma',
            :nvmet_port_id     => '1',
            :nvmet_ns_id       => '10',
          )
        end
      end

    end
  end

end
