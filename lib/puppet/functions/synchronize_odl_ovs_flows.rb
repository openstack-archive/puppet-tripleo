Puppet::Functions.create_function(:synchronize_odl_ovs_flows) do
  dispatch :synchronize_odl_ovs_flows do
    param 'String', :of_controller_uri
  end

  def synchronize_odl_ovs_flows(of_controller_uri)
    flow_tables = [
      17, 18, 19, 20, 22, 23, 24, 43, 45, 48, 50, 51, 60, 80, 81, 90, 210, 211,
      212, 213, 214, 215, 216, 217, 239, 240, 241, 242, 243, 244, 245, 246, 247
    ]
    retries = 5
    i = 0
    # wait for controller to be set
    while i <= retries
      of_ctrlr = `ovs-vsctl get-controller br-int`
      if !of_ctrlr.empty?
        break
      end
      i = i + 1
      sleep(5)
    end
    if i >= 6
      raise Puppet::Error, "OF controller for OVS was never set by ODL"
    end

    # check OF pipeline, and resync if necessary
    i = 0
    while i <= retries
      of_synchronized = true
      flow_tables.each do |table|
        of_output = `ovs-ofctl -O openflow13 dump-flows br-int | grep table=#{table}`
        if of_output.empty?
          of_synchronized = false
          break
        end
      end
      # check if need to resync
      if of_synchronized == true
        return true
      else
        resync_output = `ovs-vsctl del-controller br-int && ovs-vsctl set-controller br-int #{of_controller_uri}`
        if ! ($?.exited? && $?.exitstatus == 0)
          raise Puppet::Error, "Unable to reset OpenFlow controller for bridge br-int: #{resync_output}"
        end
      end
      i = i + 1
      # wait for openflow pipeline to be pushed by ODL
      sleep(10)
    end

    return false
  end
end
