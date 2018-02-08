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
module Puppet::Parser::Functions
  newfunction(:docker_volumes_to_storage_maps, :arity => 2, :type => :rvalue,
              :doc => <<-EOS
    This function converts an array of docker volumes (SOURCE:TARGET[:OPTIONS])
    to a pacemaker::resource::bundle storage_map (a hash).
    EOS
  ) do |argv|
    docker_volumes = argv[0]
    prefix = argv[1]

    unless docker_volumes.is_a?(Array)
      raise Puppet::ParseError, "docker_volumes_to_storage_maps: Argument 'docker_volumes' must be an array. The value given was: #{docker_volumes}"
    end
    unless prefix.is_a?(String)
      raise Puppet::ParseError, "docker_volumes_to_storage_maps: Argument 'prefix' must be an string. The value given was: #{prefix}"
    end
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

