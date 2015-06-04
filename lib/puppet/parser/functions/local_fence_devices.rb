module Puppet::Parser::Functions
  newfunction(:local_fence_devices, :arity =>2, :type => :rvalue,
              :doc => ("Given an array of fence device configs, limit them" +
                       "to fence devices whose MAC address is present on" +
                       "some of the local NICs, and prepare a hash which can be" +
                       "passed to create_resources function")) do |args|
    agent = args[0]
    devices = args[1]
    unless agent.is_a?(String) && agent.length > 0
      raise Puppet::ParseError, "local_fence_devices: Argument 'agent' must be a non-empty string. The value given was: #{agent_type}"
    end
    unless devices.is_a?(Array)
      raise Puppet::ParseError, "local_fence_devices: Argument 'devices' must be an array. The value given was: #{devices}"
    end

    # filter by agent type
    agent_type_devices = devices.select { |device| device['agent'] == agent }

    # filter by local mac address
    local_devices = agent_type_devices.select do |device|
      function_has_interface_with(['macaddress', device['host_mac']])
    end

    # construct a hash for create_resources
    return local_devices.each_with_object({}) do |device, hash|
      # disallow collisions
      if hash[device['host_mac']]
         raise Puppet::ParseError, "local_fence_devices: Only single fence device per agent per host is allowed. Collision on #{device['host_mac']} for #{agent}"
      end

      hash[device['host_mac']] = device['params'] || {}
    end
  end
end
