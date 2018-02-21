require 'ipaddr'

# Custom function to verify if the parameter is a string representing an ip address
# or an array of strings representing an ip address
# Returns true if all elements are proper ip addresses and false otherwise
module Puppet::Parser::Functions
  newfunction(:is_ip_addresses, :type => :rvalue, :doc => "Verify if a string or an array of strings are all IP addresses.") do |arg|
    if arg[0].class != String and arg[0].class != Array
      raise Puppet::ParseError, "Syntax error: #{arg[0]} must be a String or an Array"
    end
    if arg[0].class == String
      ips = [arg[0]]
    else
      ips = arg[0]
    end
    ips.each do |ip|
      begin
        tmpip = IPAddr.new ip
      rescue
        return false
      end
    end
    return true
  end
end
