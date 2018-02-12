# This is used to look up a list of service-specific fluentd configurations
# in the hiera data provided by THT.
#
# [*pos_file_path*]
#   Default location for fluentd pos files (used to track file
#   position for the 'tail' input type).
#
# [*default_format*]
#   Default regular expression against which to match log messages.
#
# [*fluentd_transform*]
#   Two value array where the first value is a regular expresion to
#   be replaced and the second one is the replacement.
#
define tripleo::profile::base::logging::fluentd::fluentd_service (
  $pos_file_path  = undef,
  $default_format = undef,
  $fluentd_transform = undef
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
    if $fluentd_transform and !empty($sources) {
      $new_source = {} + map($sources) |$source| {
          if $source['path'] {
            $newpath = {
              'path' => regsubst($source['path'],
                        $fluentd_transform[0],
                        $fluentd_transform[1])
            }

            $source + $newpath
          } else {
            $source
          }
      }
    }else{
      $new_source = {} + $sources
    }
    # Insert default values into list of sources.
    $_sources = { 'pos_file' => "${pos_file_path}/${new_source['tag']}.pos" }
      + $default_source + $new_source

    ::fluentd::config { "100-openstack-${title}.conf":
      config => {
        'source' => $_sources,
        'filter' => $filters,
        'match'  => $matches,
      }
    }
  }
}
