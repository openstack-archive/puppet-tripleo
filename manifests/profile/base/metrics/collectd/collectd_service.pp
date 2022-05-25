# This is used to look up a list of service-specific collectd plugins
# in the hiera data provided by THT.
define tripleo::profile::base::metrics::collectd::collectd_service (
) {
  $plugins = lookup("'tripleo.collectd.plugins.${title}'", undef, undef, [])

  if $plugins {
    ::tripleo::profile::base::metrics::collectd::collectd_plugin {
      $plugins: }
  }
}
