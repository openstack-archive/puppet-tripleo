#
# == Class: tripleo::profile::base::neutron::agents::mlnx
#
# Neutron Mellanox Agent profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#

class tripleo::profile::base::neutron::agents::mlnx(
  $step = Integer(hiera('step'))
) {

  file { '/etc/neutron/plugins/mlnx':
    ensure => directory,
  }

  file { '/etc/neutron/plugins/mlnx/mlnx_conf.ini':
    ensure  => file,
    owner   => 'root',
    group   => 'neutron',
    require => File['/etc/neutron/plugins/mlnx'],
    mode    => '0640',
  }

  if $step >= 3 {

    include neutron::agents::ml2::mlnx
  }
}
