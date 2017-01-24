# We use this to transform a list of unqualified plugin names
# (like ['disk', 'ntpd']) into the correct collectd plugin classes.
define tripleo::profile::base::metrics::collectd::collectd_plugin (
) {
  include "collectd::plugin::${title}"
}
