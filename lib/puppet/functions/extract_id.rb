# Custom function to extract the index from a list.
# The list are a list of hostname, and the index is the n'th
# position of the host in list
Puppet::Functions.create_function(:extract_id) do
  dispatch :extract_id do
    param 'Variant[Array, String]', :hosts
    param 'String', :hostname
  end

  def extract_id(hosts, hostname)
    if hosts.class != Array
      hosts = [hosts]
    end
    hash = Hash[hosts.map.with_index.to_a]
    return hash[hostname].to_i + 1
  end
end
