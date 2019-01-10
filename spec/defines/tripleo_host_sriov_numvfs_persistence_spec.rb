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
        :content_string => "Hashbang\n",
        :udev_rules     => ""
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
      is_expected.to contain_file('/etc/udev/rules.d/70-tripleo-reset-sriov.rules').with(
        :ensure  => 'file',
        :content => "KERNEL==\"eth0\", RUN+=\"/etc/sysconfig/allocate_vfs %k\"\nKERNEL==\"eth1\", RUN+=\"/etc/sysconfig/allocate_vfs %k\"\n",
        :group   => 'root',
        :mode    => '0755',
        :owner   => 'root',
        :replace => true
      )
      is_expected.to contain_file_line('call_ifup-local').with(
        :path => '/sbin/ifup-local',
        :line => '/etc/sysconfig/allocate_vfs $1',
      )
    end
  end
end

describe 'tripleo::host::sriov::numvfs_persistence' do

  describe 'confugure numvfs for persistence' do

    let :title do
      'numvfs'
    end

    let :params do
      {
        :name           => 'persistence',
        :vf_defs        => ['eth0:10:switchdev','eth1:8:legacy'],
        :content_string => "Hashbang\n",
        :udev_rules     => ""
      }
    end

    it 'configures persistence' do
      is_expected.to contain_file('/etc/sysconfig/allocate_vfs').with(
        :ensure  => 'file',
        :content => "Hashbang\nset -ex
set -o pipefail

if [ \"eth0\" == \"$1\" ]
then
  exec 1> >(logger -s -t $(basename $0)) 2>&1
  vendor_id=\"$(cat /sys/class/net/eth0/device/vendor)\"
  if [ \"$(cat /sys/class/net/eth0/device/sriov_numvfs)\" == \"0\" ]
  then
    echo 10 > /sys/class/net/eth0/device/sriov_numvfs
  else
    exit 0
  fi
  if [ $vendor_id == \"0x15b3\" ]
  then
    vfs_pci_list=$(grep PCI_SLOT_NAME /sys/class/net/eth0/device/virtfn*/uevent | cut -d'=' -f2)
    for pci in $vfs_pci_list
    do
      echo \"$pci\" > /sys/bus/pci/drivers/mlx5_core/unbind
    done
  fi
  interface_pci=$(grep PCI_SLOT_NAME /sys/class/net/eth0/device/uevent | cut -d'=' -f2)
  /usr/sbin/devlink dev eswitch set pci/\"$interface_pci\" mode switchdev
  if [[ \"$(/usr/sbin/devlink dev eswitch show pci/\"$interface_pci\")\" =~ \"mode switchdev\" ]]
  then
    echo \"PCI device $interface_pci set to mode switchdev.\"
  else
    echo \"Failed to set PCI device $interface_pci to mode switchdev.\"
    exit 1
  fi
  interface_device=$(cat /sys/class/net/eth0/device/device)
  if [ \"$interface_device\" == \"0x1013\" ] || [ \"$interface_device\" == \"0x1015\" ]
  then
    /usr/sbin/devlink dev eswitch set pci/\"$interface_pci\" inline-mode transport
  fi
  /usr/sbin/ethtool -K eth0 hw-tc-offload on
fi\n[ \"eth1\" == \"\$1\" ] && echo 8 > /sys/class/net/eth1/device/sriov_numvfs\n",
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
      is_expected.to contain_file('/etc/udev/rules.d/70-tripleo-reset-sriov.rules').with(
        :ensure  => 'file',
        :content => "KERNEL==\"eth0\", RUN+=\"/etc/sysconfig/allocate_vfs %k\"\nKERNEL==\"eth1\", RUN+=\"/etc/sysconfig/allocate_vfs %k\"\n",
        :group   => 'root',
        :mode    => '0755',
        :owner   => 'root',
        :replace => true
      )
      is_expected.to contain_file_line('call_ifup-local').with(
        :path => '/sbin/ifup-local',
        :line => '/etc/sysconfig/allocate_vfs $1',
      )
    end
  end
end
