# Copyright 2018 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

Facter.add('nic_alias') do
  setcode do
    os_net_config = '/usr/bin/os-net-config'
    mapping_report = ''
    if File.exist?(os_net_config)
      mapping_report =
        Facter::Core::Execution.execute("#{os_net_config} -i")
      mapping_report.delete("{}' ")
    end
    mapping_report
  end
end
