require 'spec_helper'

describe 'tripleo_swift_devices' do
  it {
    should run.with_params('r1z1-', ['192.168.1.12', '192.168.1.13'], [':%PORT%/device1', ':%PORT%/device2'])
      .and_return([
        'r1z1-192.168.1.12:%PORT%/device1',
        'r1z1-192.168.1.12:%PORT%/device2',
        'r1z1-192.168.1.13:%PORT%/device1',
        'r1z1-192.168.1.13:%PORT%/device2',
      ])
  }
end
