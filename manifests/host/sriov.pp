# == Class: tripleo::host::sriov
#
# Configures host configuration for the SR-IOV interfaces
#
# === Parameters
#
# [*number_of_vfs*]
#   (optional) List of <physical_network>:<number_of_vfs> specifying the number
#   VFs to be exposed per physical interface.
#   For example, to configure two interface with number of VFs, specify
#   it as ['eth1:4','eth2:10']
#   Defaults to []
#
class tripleo::host::sriov (
  $number_of_vfs = [],
) {

  if !empty($number_of_vfs) {
    sriov_vf_config { $number_of_vfs: ensure => present }

    # the numvfs configuration needs to be persisted for every boot
    tripleo::host::sriov::numvfs_persistence {'persistent_numvfs':
      vf_defs        => $number_of_vfs,
      content_string => "#!/bin/bash\n"
    }
  }
}
