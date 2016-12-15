# We use this to transform a list of unqualified plugin names
# (like ['disk', 'ntpd']) into the correct collectd plugin classes.
define tripleo::profile::base::metrics::collectd::plugin_helper (
) {
  include "collectd::plugin::${title}"
}
