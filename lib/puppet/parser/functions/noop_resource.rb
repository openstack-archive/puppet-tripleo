# Copyright 2017 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Author: Dan Prince <dprince@redhat.com>
#
# A function to create noop providers (set as the default) for the named
# resource. This works alongside of 'puppet apply --tags' to disable
# some custom resource types that still attempt to run commands during
# prefetch, etc.
class Puppet::Provider::Noop < Puppet::Provider

  def create
    true
  end

  def destroy
    true
  end

  def exists?
    false
  end

  # some puppet-keystone resources require this
  def self.resource_to_name(domain, name, check_for_default = true)
    return name
  end

end

module Puppet::Parser::Functions
  newfunction(:noop_resource, :type => :rvalue, :doc => "Create a default noop provider for the specified resource.") do |arg|
    if arg[0].class == String
        Puppet::Type.type(arg[0].downcase.to_sym).provide(:noop, :parent => Puppet::Provider::Noop) do
           defaultfor :osfamily => :redhat
        end
    else
    end
    return true
  end
end
