#
# == Define: tripleo::profile::base::metrics::collectd::sensubility_script
#
# This is used to download third party script for sensubility check usage. The
#
# === Parameters
#  [*source*]
#    URI from where the file should be downloaded (only http:// is supported currently)
#
#  [*scriptsdir*]
#    Directory where all downloaded scripts reside.
#
#  [*scriptname*]
#    (optional) Name of script under which it will be saved.
#    Defaults to $title
#
#  [*checksum*]
#    (optional) The checksum of the source contents. Only md5, sha256, sha224,
#    sha384 and sha512 are supported when specifying this parameter.
#    Defaults to undef
#
#  [*user*]
#    (optional) Owner of script directory and script files.
#    Defaults to 'collectd'
#
#  [*group*]
#    (optional) Group of script directory and script files.
#    Defaults to 'collectd'
#
#  [*create_bin_link*]
#    (optional) Whether the script should be linked to /usr/bin/sensubility_<script-name>.
#    Defaults to true
#
#  [*bindir*]
#    (optional) Which bin folder exactly should be used for links.
#    Defaults to '/usr/bin'
#
define tripleo::profile::base::metrics::collectd::sensubility_script (
  $source,
  $scriptsdir,
  $scriptname      = $title,
  $checksum        = undef,
  $user            = 'collectd',
  $group           = 'collectd',
  $create_bin_link = true,
  $bindir          = '/usr/bin',
) {
  file { "${scriptsdir}/${scriptname}":
    ensure         => 'present',
    source         => $source,
    checksum_value => $checksum,
    checksum       => 'md5',
    mode           => '0700',
    owner          => $user,
    group          => $group
  }

  if $create_bin_link {
    file { "${bindir}/sensubility_${scriptname}":
      ensure => 'link',
      target => "${scriptsdir}/${scriptname}",
    }
  }
}
