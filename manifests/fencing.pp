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
# [*deep_compare*]
#   Enable deep comparing of resources and bundles
#   When set to true a resource will be compared in full (options, meta parameters,..)
#   to the existing one and in case of difference it will be repushed to the CIB
#   Defaults to false
#
# [*update_settle_secs*]
#   When deep_compare is enabled and puppet updates a resource, this
#   parameter represents the number (in seconds) to wait for the cluster to settle
#   after the resource update.
#   Defaults to 600 (seconds)
#
# [*enable_instanceha*]
#  (Optional) Boolean driving the Instance HA controlplane configuration
#  Defaults to false
#
class tripleo::fencing(
  $config             = {},
  $tries              = 10,
  $try_sleep          = 3,
  $deep_compare       = false,
  $update_settle_secs = 600,
  $enable_instanceha  = hiera('tripleo::instanceha', false),
) {
  $common_params = {
    'tries' => $tries,
    'try_sleep' => $try_sleep,
    'deep_compare' => $deep_compare,
    'update_settle_secs' => $update_settle_secs
  }

  # check if instanceha is enabled
  if member(hiera('compute_instanceha_short_node_names', []), downcase($::hostname)) {
    $is_compute_instanceha_node = true
  } else {
    $is_compute_instanceha_node = false
  }

  $content = $config['devices']

  # check if the devices: section in fence.yaml contains levels.
  # if it doesn't, assume level=1 and build a hash with the content.
  if is_array($content) {
    $all_levels = {'level1' => $content}
  }
  else {
    $all_levels = $content
  }

  # collect the number of stonith levels currently defined for this system
  # and convert it to integer.
  $local_levels = 0 + $facts['stonith_levels']

  # if the number of levels defined on this system is greather than the number in hiera
  # we need to delete the delta.
  if $local_levels > $all_levels.length {
    $begin = $all_levels.length + 1
    range("${begin}", "${local_levels}").each |$level|{
        pacemaker::stonith::level{ "stonith-${level}":
          ensure            => 'absent',
          level             => $level,
          target            => '$(/usr/sbin/crm_node -n)',
          stonith_resources => [''],
          tries             => $tries,
          try_sleep         => $try_sleep,
        }
    }
  }

  $all_levels.each |$index, $levelx_devices |{

    $level = regsubst($index, 'level', '', 'G')
    $all_devices = $levelx_devices

    if $::deployment_type != 'containers' {
      $xvm_devices = local_fence_devices('fence_xvm', $all_devices)
      create_resources('pacemaker::stonith::fence_xvm', $xvm_devices, $common_params)
    }

    $ironic_devices = local_fence_devices('fence_ironic', $all_devices)
    create_resources('pacemaker::stonith::fence_ironic', $ironic_devices, $common_params)

    $redfish_devices = local_fence_devices('fence_redfish', $all_devices)
    create_resources('pacemaker::stonith::fence_redfish', $redfish_devices, $common_params)

    $ipmilan_devices = local_fence_devices('fence_ipmilan', $all_devices)
    create_resources('pacemaker::stonith::fence_ipmilan', $ipmilan_devices, $common_params)

    $kdump_devices = local_fence_devices('fence_kdump', $all_devices)
    create_resources('pacemaker::stonith::fence_kdump', $kdump_devices, $common_params)

    $rhev_devices = local_fence_devices('fence_rhevm', $all_devices)
    create_resources('pacemaker::stonith::fence_rhevm', $rhev_devices, $common_params)

    $data = {
      'xvm' => $xvm_devices, 'ironic' => $ironic_devices, 'redfish' => $redfish_devices,
      'ipmilan' => $ipmilan_devices, 'kdump' => $kdump_devices, 'rhevm' => $rhev_devices
    }

    $data.each |$items| {
      $driver = $items[0]
      $driver_devices = $items[1]

      if $driver_devices and length($driver_devices) == 1 {
        $mac = keys($driver_devices)[0]
        $safe_mac = regsubst($mac, ':', '', 'G')
        if ($enable_instanceha and $is_compute_instanceha_node) {
          $stonith_resources = [ "stonith-fence_${driver}-${safe_mac}", 'stonith-fence_compute-fence-nova' ]
        }
        else {
          $stonith_resources = [ "stonith-fence_${driver}-${safe_mac}" ]
        }
        pacemaker::stonith::level{ "stonith-${level}-${safe_mac}":
          level             => $level,
          target            => '$(/usr/sbin/crm_node -n)',
          stonith_resources => $stonith_resources,
          tries             => $tries,
          try_sleep         => $try_sleep,
        }
      }
    }
  }
}

