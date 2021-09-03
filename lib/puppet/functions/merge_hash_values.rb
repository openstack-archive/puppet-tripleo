# This function merges two hashes and concatenate the values of
# identical keys
#
# Example:
# $frontend = { 'option' => [ 'tcpka', 'tcplog' ],
#               'timeout client' => '90m' }
# $backend  = { 'option' => [ 'httpchk' ],
#               'timeout server' => '90m' }
#
# Using this function:
# $merge = merge_hash_values($frontend, $backend)
#
# Would return:
# $merge = { 'option' => [ 'tcpka', 'tcplog', 'httpchk' ],
#            'timeout client' => '90m',
#            'timeout server' => '90m' }
#

Puppet::Functions.create_function(:'merge_hash_values') do
  dispatch :merge_hash_values do
    param 'Hash', :hash1
    param 'Hash', :hash2
    return_type 'Hash'
  end

  def merge_hash_values(hash1, hash2)
    hh = hash1.merge(hash2) {|k, v1, v2| (v2 + v1).uniq()}
    return hh
  end
end
