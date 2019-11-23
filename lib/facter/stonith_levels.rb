# Copyright 2016 Red Hat, Inc.
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

Facter.add('stonith_levels') do
  setcode do

    # If crm_node is present, return true. Otherwise, return false.
    if Facter::Core::Execution.which('crm_node')
      hostname = Facter::Core::Execution.execute("crm_node -n 2> /dev/null", {})
      stonith_levels = Facter::Core::Execution.execute("pcs stonith level | sed -n \"/^Target: #{hostname}$/,/^Target:/{/^Target: #{hostname}$/b;/^Target:/b;p}\" |tail -1 | awk '{print $2}' 2> /dev/null", {})
      stonith_levels
    end

  end
end
