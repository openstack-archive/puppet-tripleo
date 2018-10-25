# Custom function to transform netmask from IP notation to
# CIDR format. Input is an IP address, output a CIDR:
# 255.255.255.0 = 24
# The CIDR formated netmask is needed for some
# Contrail configuration files
require 'ipaddr'
Puppet::Functions.create_function(:netmask_to_cidr) do
  dispatch :netmask_to_cidr do
    param 'String', :netmask
  end

  def netmask_to_cidr(netmask)
    IPAddr.new(netmask).to_i.to_s(2).count("1")
  end
end
