require 'spec_helper'

describe 'tripleo::host::sriov::numvfs_persistence' do

  describe 'confugure numvfs for persistence' do

    let :title do
      'numvfs'
    end

    let :params do
      {
        :name           => 'persistence',
        :vf_defs        => ['eth0:10','eth1:8'],
        :content_string => "Hashbang\n"
      }
    end

    it 'configures persistence' do
      is_expected.to contain_file('/etc/sysconfig/allocate_vfs').with(
        :ensure  => 'file',
        :content => "Hashbang\n[ \"eth0\" == \"\$1\" ] && echo 10 > /sys/class/net/eth0/device/sriov_numvfs\n[ \"eth1\" == \"\$1\" ] && echo 8 > /sys/class/net/eth1/device/sriov_numvfs\n",
        :group   => 'root',
        :mode    => '0755',
        :owner   => 'root',
      )
      is_expected.to contain_file('/sbin/ifup-local').with(
        :group   => 'root',
        :mode    => '0755',
        :owner   => 'root',
        :content => '#!/bin/bash',
        :replace => false,
      )
      is_expected.to contain_file_line('call_ifup-local').with(
        :path => '/sbin/ifup-local',
        :line => '/etc/sysconfig/allocate_vfs $1',
      )
    end
  end
end
