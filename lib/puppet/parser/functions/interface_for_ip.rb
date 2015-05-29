require 'ipaddr'

# Custom function to lookup the interface which matches the subnet
# of the provided IP address.
# The function iterates over all the interfaces and chooses the
# first locally assigned interface which matches the IP.
module Puppet::Parser::Functions
  newfunction(:interface_for_ip, :type => :rvalue, :doc => "Find the bind IP address for the provided subnet.") do |arg|
    if arg[0].class == String
      begin
        ip_to_find = arg[0]
        Dir.foreach('/sys/class/net/') do |interface|
          next if interface == '.' or interface == '..'
          iface_no_dash = interface.gsub('-', '_')
          interface_ip = lookupvar("ipaddress_#{iface_no_dash}")
          netmask = lookupvar("netmask_#{iface_no_dash}")
          if not interface_ip.nil? then
            ip1=IPAddr.new(interface_ip)
            ip2=IPAddr.new(ip_to_find)
            if ip1.mask(netmask) == ip2.mask(netmask) then
              return interface
            end
          end
        end
      rescue JSON::ParserError
        raise Puppet::ParseError, "Syntax error: #{arg[0]} is invalid"
      end
    else
      raise Puppet::ParseError, "Syntax error: #{arg[0]} is not a String"
    end
    return ''
  end
end
