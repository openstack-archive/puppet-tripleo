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

  if !empty($sources) or !empty($filters) or !empty($matches) {
    if !empty($sources) {
      $all = map($sources) |$values| {
        { 'pos_file' => "${pos_file_path}/${values['tag']}.pos" }
        + $default_source
        + $values
      }
      if $fluentd_transform {
        $new_source = map($all) |$values| { $values.filter|$index,$value| {$index != 'path'} +
          $values.filter|$index,$value|
            {$index == 'path'}.reduce({})|$memo,$x| {$memo + {'path' => regsubst($x[1], $fluentd_transform[0], $fluentd_transform[1]) } } }
      } else{
        $new_source = {} + $all
      }
    } else {
      $new_source = {} + $sources
    }

    ::fluentd::config { "100-openstack-${title}.conf":
      config => {
        'source' => $new_source,
        'filter' => $filters,
        'match'  => $matches,
      }
    }
  }
}
