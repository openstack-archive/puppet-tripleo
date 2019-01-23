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
        network_facts = lookupvar('networking')
        Dir.foreach('/sys/class/net/') do |interface|
          next if interface == '.' || interface == '..'
          # puppet downcases fact names, interface names can have capitals but
          # in facter 2.x they were lower case. In facter 3.x they can have
          # capitals
          iface_no_dash = interface.gsub('-', '_').downcase

          if ip1.ipv4?
            ipaddress_name = "ipaddress_#{iface_no_dash}"
            netmask_name   = "netmask_#{iface_no_dash}"
            facter_ip      = 'ip'
            facter_netmask = 'netmask'
          else
            ipaddress_name = "ipaddress6_#{iface_no_dash}"
            netmask_name   = "netmask6_#{iface_no_dash}"
            facter_ip      = 'ip6'
            facter_netmask = 'netmask6'
          end

          if network_facts.nil? or network_facts['interfaces'].nil? then
            # facter 2 facts
            interface_ip = lookupvar(ipaddress_name)
            next if interface_ip.nil?
            ip2 = IPAddr.new(interface_ip)
            netmask = lookupvar(netmask_name)
            return interface if ip1.mask(netmask) == ip2.mask(netmask)
          else
            # facter 3+ syntax:
            # networking => {
            #   ...
            #   interfaces => {
            #     br-ctlplane => {
            #       bindings => [
            #         {
            #           address => "192.168.24.1",
            #           netmask => "255.255.255.0",
            #           network => "192.168.24.0"
            #         }
            #       ],
            #       bindings6 => [
            #         {
            #           address => "fe80::5054:ff:fe22:bac3",
            #           netmask => "ffff:ffff:ffff:ffff::",
            #           network => "fe80::"
            #         }
            #       ],
            #       ip => "192.168.24.1",
            #       ip6 => "fe80::5054:ff:fe22:bac3",
            #       mac => "52:54:00:22:ba:c3",
            #       mtu => 1500,
            #       netmask => "255.255.255.0",
            #       netmask6 => "ffff:ffff:ffff:ffff::",
            #       network => "192.168.24.0",
            #       network6 => "fe80::"
            #     },
            #   },
            #   ...
            # }
            next if network_facts['interfaces'][interface].nil? or network_facts['interfaces'][interface][facter_ip].nil?
            ip2 = IPAddr.new(network_facts['interfaces'][interface][facter_ip])
            netmask = network_facts['interfaces'][interface][facter_netmask]
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
