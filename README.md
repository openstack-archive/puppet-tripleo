# puppet-openstack-cloud

[![Build Status](https://api.travis-ci.org/enovance/puppet-openstack-cloud.svg?branch=master)](https://travis-ci.org/enovance/puppet-openstack-cloud)
[![Puppet Forge](http://img.shields.io/puppetforge/v/eNovance/cloud.svg)](https://forge.puppetlabs.com/eNovance/cloud)
[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)

#### Table of Contents

1. [Overview - What is the cloud module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with puppet-openstack-cloud](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Getting Involved - How to go deeper](#involved)
7. [Development - Guide for contributing to the module](#development)
8. [Contributors - Those with commits](#contributors)
9. [Release Notes - Notes on the most recent updates to the module](#release-notes)

## Overview

The [puppet-openstack-cloud](https://wiki.openstack.org/wiki/Puppet-openstack/puppet-openstack-cloud) module is a flexible Puppet composition layer capable of configuring the core [OpenStack](http://docs.openstack.org/) services:

* [Nova](https://github.com/stackforge/puppet-nova) (compute)
* [Glance](https://github.com/stackforge/puppet-glance) (image)
* [Keystone](https://github.com/stackforge/puppet-keystone) (identity)
* [Cinder](https://github.com/stackforge/puppet-cinder) (volume)
* [Horizon](https://github.com/stackforge/puppet-horizon) (dashboard)
* [Heat](https://github.com/stackforge/puppet-heat) (orchestration)
* [Ceilometer](https://github.com/stackforge/puppet-ceilometer) (telemetry)
* [Neutron](https://github.com/stackforge/puppet-neutron) (networking)
* [Swift](https://github.com/stackforge/puppet-swift) (object storage)
* [Trove](https://github.com/stackforge/puppet-trove) (database as a service)

Cinder, Glance and Nova can use Ceph as backend storage, using [puppet-ceph](https://github.com/enovance/puppet-ceph).

Only KVM and QEMU are supported as hypervisors, for now.
Neutron use ML2 plugin with GRE and Open-vSwitch drivers.
Cinder has multi-backend support:
* RBD (default)
* NetAPP
* iSCSI
* EMC VNX direct
* NFS
Glance supports different backends:
* RBD (default)
* file
* NFS (mount a NFS share by using file backend)
* Swift
Neutron supports:
* ML2 plugin with OVS agent (GRE + VXLAN supported)
* Cisco plugin with N1KV agent (non-ML2)
Trove support is now experimental.

[Puppet Modules](http://docs.puppetlabs.com/learning/modules1.html#modules) are a collection of related contents that can be used to model the configuration of a discrete service.

These Puppet modules are based on the [openstack documentation](http://docs.openstack.org/).

## Module Description

There are a lot of moving pieces in OpenStack, consequently there are several Puppet modules needed to cover all these pieces.  Each module is then made up of several class definitions, resource declarations, defined resources, and custom types/providers.  A common pattern to reduce this complexity in Puppet is to create a composite module that bundles all these component type modules into a common set of configurations.  The cloud module is doing this compositing and exposing a set of variables needed to be successful in getting a functional stack up and running.

### Pre-module Dependencies

* [Puppet](http://docs.puppetlabs.com/puppet/) 3 or greater
* [Facter](http://www.puppetlabs.com/puppet/related-projects/facter/) 1.6.1 or greater (versions that support the osfamily fact)

### Notes about Puppet3

Puppet 3.x isn't yet available on Debian/RedHat stable osfamily, but hopefully puppet provides a Official repository, please see [this page](http://docs.puppetlabs.com/guides/puppetlabs_package_repositories.html) for the setup.

**Platforms**

These modules have been fully tested on Ubuntu Precise and Debian Wheezy and RHEL 6.

## Setup

**What the cloud module affects**

* The entirety of OpenStack!

### Installing Puppet

Puppet Labs provides two tools for getting started with managing configuration modeling with Puppet, Puppet Enterprise or its underlying opensource projects, i.e. Puppet and MCollective.

* [Puppet Enterprise](http://docs.puppetlabs.com/#puppet-enterprisepelatest) is a complete configuration management platform, with an optimized set of components proven to work well together.  Is free up to 10 nodes so if you're just using Puppet for OpenStack management this might just work perfectly.  It will come configured with a handful of extra components that make for a richer experience, like a web interface for managing the orchestration of Puppet and certificate management.
* [Puppet](http://docs.puppetlabs.com/#puppetpuppet) manages your servers: you describe machine configurations in an easy-to-read declarative language, and Puppet will bring your systems into the desired state and keep them there.  This is the opensource version of Puppet and should be available in your operating system's package repositories but it is generally suggested you use the [yum](http://yum.puppetlabs.com) or [apt](http://apt.puppetlabs.com) repositories from Puppet Labs if possible.

Consult the documentation linked above to help you make your decision but don't fret about the choice to much, opensource Puppet agents are compatible with Puppet Enterprise Puppet masters.

### Optional Puppet features

The swift portions of this module needs Puppet's [exported resources](http://docs.puppetlabs.com/puppet/3/reference/lang_exported.html).  Exported resources leverages the PuppetDB to export and share data across other Puppet managed nodes.

### Installing latest unstable cloud module from source

    cd /etc/puppet/modules
    git clone git@github.com:redhat-openstack/openstack-puppet-modules.git modules
    cd modules
    git checkout -b puppet-openstack-cloud origin/enovance
    gem install --no-ri --no-rdoc r10k
    # a debian package is available in jessie
    PUPPETFILE=./Puppetfile PUPPETFILE_DIR=../ r10k --verbose 3 puppetfile install

**Pre-puppet setup**

The things that follow can be handled by Puppet but are out of scope of this document and are not included in the cloud module.

### Beginning with puppet-openstack-cloud

Utilization of this module can come in many forms.  It was designed to be capable of deploying all services to a single node or distributed across several.  This is not an exhaustive list, we recommend you consult and understand all the manifests included in this module and the [core openstack](http://docs.openstack.org) documentation.


## Implementation

(more doc should be written here)

## Limitations

* Deploys only with rabbitmq and mysql RPC/data backends.
* Not backwards compatible with pre-2.x release of the cloud modules.

## Getting Involved

Need a feature? Found a bug? Let us know!

We are extremely interested in growing a community of OpenStack experts and users around these modules so they can serve as an example of consolidated best practices of how to deploy openstack.

The best way to get help with this set of modules is to email the group associated with this project:

  dev [at] enovance [dot] com

Issues should be opened here:

  https://github.com/enovance/puppet-openstack-cloud/issues


## Contributors

* https://github.com/enovance/puppet-openstack-cloud/graphs/contributors

## Release Notes

See [CHANGELOG](https://github.com/enovance/puppet-openstack-cloud/blob/master/CHANGELOG.md) file.
