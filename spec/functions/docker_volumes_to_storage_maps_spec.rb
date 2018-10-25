require 'spec_helper'

describe 'docker_volumes_to_storage_maps' do
  it {
    should run.with_params(["/src/vol1:/tgt/vol1", "/src/vol2:/tgt/vol2:ro"], "my-prefix")
      .and_return({
        "my-prefix-src-vol1" => {
          "source-dir" => "/src/vol1",
          "target-dir" => "/tgt/vol1",
          "options"    => "rw",
        },
        "my-prefix-src-vol2" => {
          "source-dir" => "/src/vol2",
          "target-dir" => "/tgt/vol2",
          "options"    => "ro",
        }
      })
  }
end
