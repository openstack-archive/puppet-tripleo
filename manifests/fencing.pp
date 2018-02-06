# == Class: tripleo::fencing
#
# Configure Pacemaker fencing devices for TripleO.
#
# === Parameters:
#
# [*config*]
#  JSON config of fencing devices, using the following structure:
#    {
#      "devices": [
#        {
#          "agent": "AGENT_NAME",
#          "host_mac": "HOST_MAC_ADDRESS",
#          "params": {"PARAM_NAME": "PARAM_VALUE"}
#        }
#      ]
#    }
#  For instance:
#    {
#      "devices": [
#        {
#          "agent": "fence_xvm",
#          "host_mac": "52:54:00:aa:bb:cc",
#          "params": {
#            "multicast_address": "225.0.0.12",
#            "port": "baremetal_0",
#            "manage_fw": true,
#            "manage_key_file": true,
#            "key_file": "/etc/fence_xvm.key",
#            "key_file_password": "abcdef"
#          }
#        }
#      ]
#    }
#  Defaults to {}
#
# [*tries*]
#  Number of attempts when creating fence devices and constraints.
#  Defaults to 10
#
# [*try_sleep*]
#  Delay (in seconds) between attempts when creating fence devices
#  and constraints.
#  Defaults to 3
#
# [*enable_instanceha*]
#  (Optional) Boolean driving the Instance HA controlplane configuration
#  Defaults to false
#
class tripleo::fencing(
  $config            = {},
  $tries             = 10,
  $try_sleep         = 3,
  $enable_instanceha = hiera('tripleo::instanceha', false),
) {
  $common_params = {
    'tries' => $tries,
    'try_sleep' => $try_sleep,
  }
  # We will create stonith levels *only* if the node is a compute instanceha one
  if member(hiera('compute_instanceha_short_node_names', []), downcase($::hostname)) {
    $is_compute_instanceha_node = true
  } else {
    $is_compute_instanceha_node = false
  }


  $all_devices = $config['devices']

  $xvm_devices = local_fence_devices('fence_xvm', $all_devices)
  create_resources('pacemaker::stonith::fence_xvm', $xvm_devices, $common_params)

  $ipmilan_devices = local_fence_devices('fence_ipmilan', $all_devices)
  create_resources('pacemaker::stonith::fence_ipmilan', $ipmilan_devices, $common_params)
  if ($enable_instanceha and $is_compute_instanceha_node) {
    if length($ipmilan_devices) != 1 {
      fail('Multiple (or zero) IPmilan devices for a single host are not supported with instance HA')
    }
    # Get the first (and only) key which is the mac-address
    $mac = keys($ipmilan_devices)[0]
    $safe_mac = regsubst($mac, ':', '', 'G')
    $stonith_resources = [ "stonith-fence_ipmilan-${safe_mac}", 'stonith-fence_compute-fence-nova' ]
    Pcmk_stonith <||> -> Pcmk_stonith_level <||>
    pacemaker::stonith::level{ "stonith-level-${safe_mac}":
      level             => 1,
      target            => '$(/usr/sbin/crm_node -n)',
      stonith_resources => $stonith_resources,
      tries             => $tries,
      try_sleep         => $try_sleep,
    }
  }


  $ironic_devices = local_fence_devices('fence_ironic', $all_devices)
  create_resources('pacemaker::stonith::fence_ironic', $ironic_devices, $common_params)
}
