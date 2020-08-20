# Custom function to extract the current number of replicas for a pacemaker
# resource, as defined in the pacemaker cluster.
# Input is the name of a pacemaker bundle resource
# Output is the number of replicas for that resource or 0 if not found
Puppet::Functions.create_function(:'pacemaker_bundle_replicas') do
  dispatch :pacemaker_bundle_replicas do
    param 'String', :bundle
    return_type 'Integer'
  end

  def pacemaker_bundle_replicas(bundle)
    # the name of the node holding the replicas attribute varies based on the
    # container engine used (podman, docker...), so match via attributes instead
    replicas = `cibadmin -Q | xmllint --xpath "string(//bundle[@id='#{bundle}']/*[boolean(@image) and boolean(@run-command)]/@replicas)" -`

    # post-condition: 0 in case the bundle does not exist or an error occurred
    if $?.success? && !replicas.empty?
      return Integer(replicas)
    else
      return 0
    end
  end
end
