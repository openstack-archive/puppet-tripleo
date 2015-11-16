require 'ipaddr'

# Custom function to lookup the interface which matches the subnet
# of the provided IP address.
# The function iterates over all the interfaces and chooses the
# first locally assigned interface which matches the IP.
module Puppet::Parser::Functions
  newfunction(:interface_for_ip, :type => :rvalue, :doc => "Find the bind IP address for the provided subnet.") do |arg|
    if arg[0].class == String
      begin
        ip1 = IPAddr.new(arg[0])
        Dir.foreach('/sys/class/net/') do |interface|
          next if interface == '.' || interface == '..'
          iface_no_dash = interface.gsub('-', '_')

          if ip1.ipv4?
            ipaddress_name = "ipaddress_#{iface_no_dash}"
            netmask_name   = "netmask_#{iface_no_dash}"
          else
            ipaddress_name = "ipaddress6_#{iface_no_dash}"
            netmask_name   = "netmask6_#{iface_no_dash}"
          end

          interface_ip = lookupvar(ipaddress_name)
          netmask = lookupvar(netmask_name)
          unless interface_ip.nil? then
            ip2 = IPAddr.new(interface_ip)
            return interface if ip1.mask(netmask) == ip2.mask(netmask)
          end
        end
      rescue IPAddr::InvalidAddressError => e
        raise Puppet::ParseError, "#{e}: #{arg[0]}"
      end
    else
      raise Puppet::ParseError, "Syntax error: #{arg[0]} must be a String"
    end
    return ''
  end
end
