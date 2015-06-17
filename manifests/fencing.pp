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
class tripleo::fencing(
  $config = {},
  $tries = 10,
  $try_sleep = 3,
) {
  $common_params = {
    'tries' => $tries,
    'try_sleep' => $try_sleep,
  }

  $all_devices = $config['devices']

  $xvm_devices = local_fence_devices('fence_xvm', $all_devices)
  create_resources('pacemaker::stonith::fence_xvm', $xvm_devices, $common_params)

  $ipmilan_devices = local_fence_devices('fence_ipmilan', $all_devices)
  create_resources('pacemaker::stonith::fence_ipmilan', $ipmilan_devices, $common_params)
}
