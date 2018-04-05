#
# == Class: tripleo::profile::base::cinder::volume::nvmeof
#
# NVMeOF Cinder Volume profile for tripleo
#
# === Parameters
#
# [*target_ip_address*]
#   (Required) The IP address of NVMe target
#
# [*target_port*]
#   (Required) Port that NVMe target is listening on
#
# [*target_helper*]
#   (Required) Target user-land tool to use
#
# [*target_protocol*]
#   (Required) Target rotocol to use
#
# [*target_prefix*]
#   (Optional) Prefix for LVM volumes
#   Defaults to 'nvme-subsystem'
#
# [*nvmet_port_id*]
#   (Optional) Port id of the NVMe target
#   Defaults to '1'
#
# [*nvmet_ns_id*]
#   (Optional) The namespace id associated with the subsystem
#   Defaults to '10'
#
# [*volume_backend_name*]
#   (Optional) Name given to the Cinder backend
#   Defaults to 'tripleo_nvmeof'
#
# [*volume_driver*]
#   (Optional) Driver to use for volume creation
#   Defaults to 'cinder.volume.drivers.lvm.LVMVolumeDriver'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cinder::volume::nvmeof (
  $target_ip_address,
  $target_port,
  $target_helper,
  $target_protocol,
  $target_prefix        = 'nvme-subsystem',
  $nvmet_port_id        = '1',
  $nvmet_ns_id          = '10',
  $volume_backend_name  = hiera('cinder::backend::nvmeof::volume_backend_name', 'tripleo_nvmeof'),
  $volume_driver        = 'cinder.volume.drivers.lvm.LVMVolumeDriver',
  $step                 = Integer(hiera('step')),
) {
  include ::tripleo::profile::base::cinder::volume

  if $step >= 4 {
    cinder::backend::nvmeof { $volume_backend_name :
      target_ip_address   => normalize_ip_for_uri($target_ip_address),
      target_port         => $target_port,
      target_helper       => $target_helper,
      target_protocol     => $target_protocol,
      target_prefix       => $target_prefix,
      nvmet_port_id       => $nvmet_port_id,
      nvmet_ns_id         => $nvmet_ns_id,
      volume_backend_name => $volume_backend_name,
      volume_driver       => $volume_driver,
    }
  }

}

