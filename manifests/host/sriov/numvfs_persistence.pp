#
# tripleo::host::sriov::numvfs_persistence used by tripleo::host::sriov
#
# === Parameters:
#
# [*vf_defs*]
#   (required) Array of <physical_interface>:<numvfs>.
#   Example: ['eth1:10','eth2:8']
#
# [*content_string*]
#   (required) String which shall be written to the script file.
#
# [*udev_rules*]
#   (required) String of lines to write to udev rules to ensure
#   VFs are reconfigured if the PCI devices are removed and
#   readded without rebooting (e.g. when physical functions were
#   allocated to VMs)
#
define tripleo::host::sriov::numvfs_persistence(
  $vf_defs,
  $content_string,
  $udev_rules
){
  # Since reduce isn't available, we use recursion to iterate each entries of
  # "physical_interface:vfs" and accumulate the content that needs to be
  # written to the script file.
  include ::stdlib

  if empty($vf_defs) {
    file { '/etc/sysconfig/allocate_vfs':
      ensure  => file,
      content => $content_string,
      group   => 'root',
      mode    => '0755',
      owner   => 'root',
    }

    file { '/sbin/ifup-local':
      group   => 'root',
      mode    => '0755',
      owner   => 'root',
      content => '#!/bin/bash',
      replace => false
    }

    file { '/etc/udev/rules.d/70-tripleo-reset-sriov.rules':
      ensure  => file,
      group   => 'root',
      mode    => '0755',
      owner   => 'root',
      content => $udev_rules,
      replace => true,
    }


    file_line { 'call_ifup-local':
      path    => '/sbin/ifup-local',
      line    => '/etc/sysconfig/allocate_vfs $1',
      require => File['/sbin/ifup-local'],
    }
  } else {
    $vfspec = split($vf_defs[0], ':')
    $interface = $vfspec[0]
    $count = $vfspec[1]
    if (length($vfspec) == 3) {
      $mode = $vfspec[2]
    } else {
      $mode = 'legacy'
    }
    if ($mode == 'switchdev') {
      $vfdef_str = epp('tripleo/switchdev/switchdev.epp', {
        'content_string' => "${content_string}",
        'interface' => "${interface}",
        'count' => "${count}"
        })
    } else {
      $vfdef_str = "${content_string}[ \"${interface}\" == \"\$1\" ] && echo ${count} > /sys/class/net/${interface}/device/sriov_numvfs\n"
    }
    $udev_str = "${udev_rules}KERNEL==\"${interface}\", RUN+=\"/etc/sysconfig/allocate_vfs %k\"\n"
    tripleo::host::sriov::numvfs_persistence{"mapped ${interface}":
      vf_defs        => delete_at($vf_defs, 0),
      content_string => $vfdef_str,
      udev_rules     => $udev_str
    }
  }
}

