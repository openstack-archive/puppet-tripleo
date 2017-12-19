# This is used to look up a list of service-specific fluentd configurations
# in the hiera data provided by THT.
#
# [*pos_file_path*]
#   Default location for fluentd pos files (used to track file
#   position for the 'tail' input type).
#
# [*default_format*]
#   Default regular expression against which to match log messages.
define tripleo::profile::base::logging::fluentd::fluentd_service (
  $pos_file_path  = undef,
  $default_format = undef
) {
  $sources = hiera("tripleo_fluentd_sources_${title}", [])
  $filters = hiera("tripleo_fluentd_filters_${title}", [])
  $matches = hiera("tripleo_fluentd_matches_${title}", [])

  $default_source = {
    format => $default_format,
    type   => 'tail',
  }

  # Check that we have something to configure to avoid creating
  # stub config files.
  if !empty($sources) or !empty($filters) or !empty($matches) {

    # Insert default values into list of sources.
    $_sources = $sources.map |$src| {
      $default_source
      + {pos_file => "${pos_file_path}/${src['tag']}.pos"}
      + $src
    }

    ::fluentd::config { "100-openstack-${title}.conf":
      config => {
        'source' => $_sources,
        'filter' => $filters,
        'match'  => $matches,
      }
    }
  }
}
