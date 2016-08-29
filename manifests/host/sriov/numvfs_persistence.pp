#
# tripleo::host::sriov::numvfs_persistence used by tripleo::host::sriov
#
# === Parameters:
#
# [*vf_defs*]
#   (required) Array of of <physical_interface>:<numvfs>.
#   Example: ['eth1:10','eth2:8']
#
# [*content_string*]
#   (required) String which shall be written to the script file.
#
define tripleo::host::sriov::numvfs_persistence(
  $vf_defs,
  $content_string
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

    file_line { 'call_ifup-local':
      path    => '/sbin/ifup-local',
      line    => '/etc/sysconfig/allocate_vfs $1',
      require => File['/sbin/ifup-local'],
    }
  } else {
    $vfspec = split($vf_defs[0], ':')
    $interface = $vfspec[0]
    $count = $vfspec[1]
    $vfdef_str = "${content_string}[ \"${interface}\" == \"\$1\" ] && echo ${count} > /sys/class/net/${interface}/device/sriov_numvfs\n"
    tripleo::host::sriov::numvfs_persistence{"mapped ${interface}":
      vf_defs        => delete_at($vf_defs, 0),
      content_string => $vfdef_str
    }
  }
}

