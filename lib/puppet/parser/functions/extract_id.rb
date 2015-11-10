# Custom function to extract the index from a list.
# The list are a list of hostname, and the index is the n'th
# position of the host in list
module Puppet::Parser::Functions
  newfunction(:extract_id, :type => :rvalue) do |argv|
    hosts = argv[0]
    if hosts.class != Array
      hosts = [hosts]
    end
    hostname = argv[1]
    hash = Hash[hosts.map.with_index.to_a]
    return hash[hostname].to_i + 1
  end
end
