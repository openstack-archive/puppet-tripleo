# This custom function converts an array of docker volumes to the storage_maps
# hash required by the pacemaker::resource::bundle resource. A prefix is added
# to each entry in the storage map to ensure the Puppet resources are unique.
#
# Given:
#   docker_volumes = ["/src/vol1:/tgt/vol1", "/src/vol2:/tgt/vol2:ro"]
#   prefix = "my-prefix"
# Returns:
#   storage_maps = {
#     "my-prefix-src-vol1" => {
#       "source-dir" => "/src/vol1",
#       "target-dir" => "/tgt/vol1",
#       "options"    => "rw",
#     },
#     "my-prefix-src-vol2" => {
#       "source-dir" => "/src/vol2",
#       "target-dir" => "/tgt/vol2",
#       "options"    => "ro",
#     }
#   }
Puppet::Functions.create_function(:'docker_volumes_to_storage_maps') do
  dispatch :docker_volumes_to_storage_maps do
    param 'Array', :docker_volumes
    param 'String', :prefix
    return_type 'Hash'
  end

  def docker_volumes_to_storage_maps(docker_volumes, prefix)
    storage_maps = Hash.new
    docker_volumes.each do |docker_vol|
      source, target, options = docker_vol.split(":")
      unless options
        options = "rw"
      end
      storage_maps[prefix + source.gsub("/", "-")] = {
        "source-dir" => source,
        "target-dir" => target,
        "options"    => options,
      }
    end
    return storage_maps
  end
end

