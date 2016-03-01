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

module Puppet::Parser::Functions
  newfunction(:list_to_hash, :type => :rvalue, :doc => <<-EOS
    This function returns an hash from a specified array
    EOS
  ) do |argv|
    arr1 = argv[0]
    arr2 = argv[1]
    h = arr1.each_with_object({}) { |v,h| h[v] = arr2 }
    return h
  end
end
