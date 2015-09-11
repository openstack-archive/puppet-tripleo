Puppet::Type.newtype(:package_manifest) do

  ensurable
  newparam(:path, :namevar => true) do
    newvalues(/\S+\/\S+/)
  end

end
