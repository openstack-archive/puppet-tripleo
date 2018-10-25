require 'ipaddr'

# Custom function to verify if the parameter is a string representing an ip address
# or an array of strings representing an ip address
# Returns true if all elements are proper ip addresses and false otherwise
Puppet::Functions.create_function(:is_ip_addresses) do
  dispatch :is_ip_addresses do
    param 'Variant[Array, String, Undef]', :ip_addr
  end

  def is_ip_addresses(ip_addr)
    if not ip_addr
      return false
    end
    if ip_addr.class == String
      ips = [ip_addr]
    else
      ips = ip_addr
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
