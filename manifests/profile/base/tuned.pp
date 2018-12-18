# == Class: tripleo::profile::base::tuned
#
# Configures tuned service.
#
# === Parameters:
#
# [*profile*]
#   (optional) tuned active profile.
#   Defaults to 'throughput-performance'
#
# [*custom_profile*]
#   (optional) string in INI format defining a custom profile
#   Defaults to undef
#
class tripleo::profile::base::tuned (
  $profile        = 'throughput-performance',
  $custom_profile = undef
) {
  ensure_resource('package', 'tuned', { ensure => 'present' })
  if !empty($custom_profile) {
    file { "/etc/tuned/${profile}":
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    } -> file { "/etc/tuned/${profile}/tuned.conf":
      ensure  => present,
      before  => Exec['tuned-adm'],
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $custom_profile,
    }
  }
  exec { 'tuned-adm':
    path    => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    command => "tuned-adm profile ${profile}",
    unless  => "tuned-adm active | grep -q '${profile}'",
    require => Package['tuned'],
  }
}
