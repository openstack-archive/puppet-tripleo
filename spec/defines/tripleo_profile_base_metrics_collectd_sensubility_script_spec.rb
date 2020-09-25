require 'spec_helper'

describe 'tripleo::profile::base::metrics::collectd::sensubility_script' do
  let(:title) { 'test' }

  let :params do {
    :scriptname => 'test',
    :checksum   => '227e8f542d95e416462a7f17652da655',
    :user       => 'collectd',
    :group      => 'collectd',
    :source     => 'http://some.uri',
    :scriptsdir => '/some/path'
  }
  end

  shared_examples_for 'tripleo::profile::base::metrics::collectd::sensubility_script' do
    context 'with basic parameters' do
      it 'should  download the script' do
        is_expected.to contain_file('/some/path/test').with(
          :ensure         => 'present',
          :owner          => 'collectd',
          :group          => 'collectd',
          :mode           => '0700',
          :source         => 'http://some.uri',
          :checksum_value => '227e8f542d95e416462a7f17652da655',
        )

        is_expected.to contain_file('/usr/bin/sensubility_test').with(
          :ensure => 'link',
          :target => '/some/path/test',
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::metrics::collectd::sensubility_script'
    end
  end
end
