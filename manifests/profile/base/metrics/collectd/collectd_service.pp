# This is used to look up a list of service-specific collectd plugins
# in the hiera data provided by THT.
define tripleo::profile::base::metrics::collectd::collectd_service (
) {
  $plugins = hiera("tripleo.collectd.plugins.${title}", [])

  if $plugins {
    ::tripleo::profile::base::metrics::collectd::collectd_plugin {
      $plugins: }
  }
}
