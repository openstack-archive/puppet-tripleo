# Build Swift devices list from the parts, e.g. for:
# raw_disk_prefix = 'r1z1-'
# swift_storage_node_ips = ['192.168.1.12', '192.168.1.13']
# raw_disks = [':%PORT%/device1', ':%PORT%/device2']
#
# devices will be ['r1z1-192.168.1.12:%PORT%/device1',
#                  'r1z1-192.168.1.12:%PORT%/device2'
#                  'r1z1-192.168.1.13:%PORT%/device1'
#                  'r1z1-192.168.1.13:%PORT%/device2']
module Puppet::Parser::Functions
  newfunction(:tripleo_swift_devices, :arity =>3, :type => :rvalue,
              :doc => ("Build list of swift devices the TripleO way:" +
                       "from a raw disk prefix, a list of swift storage" +
                       "node IPs, and a list of raw disks.")) do |args|

    raw_disk_prefix = args[0]
    swift_node_ips = args[1]
    raw_disks = args[2]

    unless raw_disk_prefix.is_a?(String)
      raise Puppet::ParseError, "tripleo_swift_devices: Argument 'raw_disk_prefix' must be a string. The value given was: #{raw_disk_prefix}"
    end
    unless swift_node_ips.is_a?(Array)
      raise Puppet::ParseError, "tripleo_swift_devices: Argument 'swift_node_ips' must be an array. The value given was: #{swift_node_ips}"
    end
    unless raw_disks.is_a?(Array)
      raise Puppet::ParseError, "tripleo_swift_devices: Argument 'raw_disks' must be an array. The value given was: #{raw_disks}"
    end

    devices = []
    for ip in swift_node_ips do
      for disk in raw_disks do
        devices << "#{raw_disk_prefix}#{ip}#{disk}"
      end
    end

    return devices
  end
end
