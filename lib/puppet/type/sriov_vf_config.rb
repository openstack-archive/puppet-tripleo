Puppet::Type.newtype(:sriov_vf_config) do

  ensurable

  newparam(:name) do
    desc "sriov_numvfs conf as <physical_network>:<number_of_vfs>:<mode> format"
    newvalues(/^[a-zA-Z0-9\-_]+:[0-9]+(:(switchdev|legacy))?$/)
  end

end
