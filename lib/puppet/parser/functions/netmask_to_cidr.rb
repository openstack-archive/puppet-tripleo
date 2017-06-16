# Custom function to transform netmask from IP notation to
# CIDR format. Input is an IP address, output a CIDR:
# 255.255.255.0 = 24
# The CIDR formated netmask is needed for some
# Contrail configuration files
require 'ipaddr'
module Puppet::Parser::Functions
  newfunction(:netmask_to_cidr, :type => :rvalue) do |args|
    if args[0].class != String
      raise Puppet::ParseError, "Syntax error: #{args[0]} must be a String"
    end
    IPAddr.new(args[0]).to_i.to_s(2).count("1")
  end
end
