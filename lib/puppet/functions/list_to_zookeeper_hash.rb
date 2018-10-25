# Custom function to convert a list of ips to a map
# like {'ip' => xxx.xxx.xxx.xxx }. This function is needed
# because a not-so-good design of the puppet-midonet module
# and we hope to deprecate it soon.

Puppet::Functions.create_function(:list_to_zookeeper_hash) do
  dispatch :list_to_zookeeper_hash do
    param 'Variant[Array, String]', :zk_list
  end

  def list_to_zookeeper_hash(zk_list)
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
