# Custom function to convert a list of ips to a map
# like {'ip' => xxx.xxx.xxx.xxx }. This function is needed
# because a not-so-good design of the puppet-midonet module
# and we hope to deprecate it soon.

module Puppet::Parser::Functions
  newfunction(:list_to_zookeeper_hash, :type => :rvalue, :doc => <<-EOS
    This function returns Zookeper configuration list of hash
    EOS
  ) do |argv|
    zk_list = argv[0]
    if zk_list.class != Array
      zk_list = [zk_list]
    end
    result = Array.new
    zk_list.each do |zk_ip|
      zk_map = Hash.new
      zk_map['ip'] = zk_ip
      zk_map['port'] = 2181
      result.push(zk_map)
    end
    return result
  end
end
