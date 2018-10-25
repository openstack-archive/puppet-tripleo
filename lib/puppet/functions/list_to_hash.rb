# This function is an hack because we are not enabling Puppet parser
# that would allow us to manipulate data iterations directly in manifests.
#
# Example:
# keystone_vips = ['192.168.0.1:5000', '192.168.0.2:5000']
# $keystone_bind_opts = ['transparent']
#
# Using this function:
# $keystone_vips_hash = list_to_hash($keystone_vips, $keystone_bind_opts)
#
# Would return:
# $keystone_vips_hash = {
#   '192.168.0.1:5000' => ['transparent'],
#   '192.168.0.2:5000' => ['transparent'],
# }
#
# Disclaimer: this function is an hack and will disappear once TripleO enable
# Puppet parser.
#

Puppet::Functions.create_function(:list_to_hash) do
  dispatch :list_to_hash do
    param 'Array', :arr1
    param 'Array', :arr2
  end

  def list_to_hash(arr1, arr2)
    hh = arr1.each_with_object({}) { |v,h| h[v] = arr2 }
    return hh
  end
end
