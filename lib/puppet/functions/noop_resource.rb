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

  # generic resource interfaces
  def create
    true
  end

  def destroy
    true
  end

  def exists?
    false
  end

  # package resource
  def install
    true
  end

  def uninstall
    true
  end

  def latest
    true
  end

  def update
    true
  end

  def purge
    true
  end

  def self.instances
    []
  end

  # service resource
  def status
    0
  end

  def start
    true
  end

  def stop
    true
  end

  # some puppet-keystone resources require this
  def self.resource_to_name(domain, name, check_for_default = true)
    return name
  end

end

Puppet::Functions.create_function(:noop_resource) do
  dispatch :noop_resource do
    param 'String', :res
  end

  def noop_resource(res)
    Puppet::Type.type(res.downcase.to_sym).provide(:noop, :parent => Puppet::Provider::Noop) do
      defaultfor :osfamily => :redhat
    end
    return true
  end
end
