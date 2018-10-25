# Build Swift devices list from the parts, e.g. for:
# raw_disk_prefix = 'r1z1-'
# swift_storage_node_ips = ['192.168.1.12', '192.168.1.13']
# raw_disks = [':%PORT%/device1', ':%PORT%/device2']
#
# devices will be ['r1z1-192.168.1.12:%PORT%/device1',
#                  'r1z1-192.168.1.12:%PORT%/device2'
#                  'r1z1-192.168.1.13:%PORT%/device1'
#                  'r1z1-192.168.1.13:%PORT%/device2']
Puppet::Functions.create_function(:tripleo_swift_devices) do
  dispatch :tripleo_swift_devices do
    param 'String', :raw_disk_prefix
    param 'Array', :swift_node_ips
    param 'Array', :raw_disks
  end

  def tripleo_swift_devices(raw_disk_prefix, swift_node_ips, raw_disks)
    devices = []
    for ip in swift_node_ips do
      for disk in raw_disks do
        devices << "#{raw_disk_prefix}#{ip}#{disk}"
      end
    end

    return devices
  end
end
