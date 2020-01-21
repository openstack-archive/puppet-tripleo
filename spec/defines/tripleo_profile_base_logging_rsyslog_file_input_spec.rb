require 'spec_helper'

foo_log_conf = <<-EOS
# foobar_foo
input(type="imfile"
  file="/path/to/foo.log"
  tag="foo"
  startmsg.regex="test"
)
EOS
bar_log_conf = <<-EOS
# foobar_bar
input(type="imfile"
  file="/path/to/bar.log"
  tag="bar"
  startmsg.regex="baz"
)
EOS

describe 'tripleo::profile::base::logging::rsyslog::file_input' do
  let(:title) { 'foobar' }

  let :pre_condition do
    'include ::rsyslog::server'
  end

  shared_examples_for 'tripleo::profile::base::logging::rsyslog::file_input' do
    context 'with basic parameters to configure rsyslog file inputs' do
      let :params do {
        'sources' => [
          {'file' => '/path/to/foo.log', 'tag' => 'foo'},
          {'file' => '/path/to/bar.log', 'tag' => 'bar', 'startmsg.regex' => 'baz'}
        ],
        'default_startmsg' => 'test'
      }
      end

      it 'should configure the given file inputs' do
        should contain_concat__fragment('rsyslog::component::input::foobar_foo').with({
          :target => '/etc/rsyslog.d/50_rsyslog.conf',
          :content => foo_log_conf,
        })
        should contain_concat__fragment('rsyslog::component::input::foobar_bar').with({
          :target => '/etc/rsyslog.d/50_rsyslog.conf',
          :content => bar_log_conf,
        })
      end
    end

    context 'with non-array sources to configure rsyslog file input' do
      let :params do {
        'sources' => {'file' => '/path/to/foo.log', 'tag' => 'foo'},
        'default_startmsg' => 'test'
      }
      end

      it 'should configure the given file inputs' do
        should contain_concat__fragment('rsyslog::component::input::foobar_foo').with({
          :target => '/etc/rsyslog.d/50_rsyslog.conf',
          :content => foo_log_conf,
        })
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::logging::rsyslog::file_input'
    end
  end
end
