# == Class: tripleo::profile::base::metrics::collectd
#
# Collectd configuration for TripleO
#
# === Parameters
#
# [*collectd_plugins*]
#   (Optional) List. A list of collectd plugins to configure (the
#   corresponding collectd::plugin::NAME class must exist in the
#   collectd package).
#
# [*collectd_server*]
#   (Optional) String. The name or address of a collectd server to
#   which we should send metrics.
#
# [*collectd_port*]
#   (Optional) Integer. The port to which we will connect on the
#   collectd server.
#
# [*collectd_username*]
#   (Optional) String.  Username for authenticating to the remote
#   collectd server.
#
# [*collectd_password*]
#   (Optional) String. Password for authenticating to the remote
#   collectd server.
#
# [*collectd_securitylevel*]
#   (Optional) String.
#
# [*collectd_interface*]
#   (Optional) String. Name of a network interface.
#
# [*collectd_graphite_server*]
#   (Optional) String. The name or address of a graphite server to
#   which we should send metrics.
#
# [*collectd_graphite_port*]
#   (Optional) Integer.  This is the port to which we will connect on
#   the graphite server. Defaults to 2004.
#
# [*collectd_graphite_prefix*]
#   (Optional) String. Prefix to add to metric names. Defaults to
#   'overcloud.'.
#
# [*collectd_graphite_protocol*]
#   (Optional) String. One of 'udp' or 'tcp'.
#
class tripleo::profile::base::metrics::collectd (
  $collectd_plugins = [],

  $collectd_server = undef,
  $collectd_port = 25826,
  $collectd_username = undef,
  $collectd_password = undef,
  $collectd_securitylevel = undef,

  $collectd_graphite_server = undef,
  $collectd_graphite_port = 2004,
  $collectd_graphite_prefix = undef,
  $collectd_graphite_protocol = 'udp'
) {
  include ::collectd
  ::tripleo::profile::base::metrics::collectd::plugin_helper { $collectd_plugins: }

  if ! ($collectd_graphite_protocol in ['udp', 'tcp']) {
    fail("collectd_graphite_protocol must be one of 'udp' or 'tcp'")
  }

  if $collectd_server {
    ::collectd::plugin::network::server { $collectd_server:
      username      => $collectd_username,
      password      => $collectd_password,
      port          => $collectd_port,
      securitylevel => $collectd_securitylevel,
    }
  }

  if $collectd_graphite_server {
    ::collectd::plugin::write_graphite::carbon { 'openstack_graphite':
      graphitehost   => $collectd_graphite_server,
      graphiteport   => $collectd_graphite_port,
      graphiteprefix => $collectd_graphite_prefix,
      protocol       => $collectd_graphite_protocol,
    }
  }
}

