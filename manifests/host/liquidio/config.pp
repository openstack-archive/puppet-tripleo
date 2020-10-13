# == Class: tripleo::host::liquidio::config
#
# This class is used to manage Liquidio configurations.
#
# === Parameters
#
# [*liquidio_config*]
#   (optional) Allow configuration of liquidio.conf configurations.
#   The value is a hash of liquidio_config resources. Example:
#   server_config =>
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#
#   NOTE: { 'DEFAULT/foo': value => 'fooValue'; 'DEFAULT/bar': value => 'barValue'} is invalid.
#
#   In yaml format, Example:
#   liquidio_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
class tripleo::host::liquidio::config (
  $liquidio_config = {}
) {

  validate_legacy(Hash, 'validate_hash', $liquidio_config)

  create_resources('liquidio_config', $liquidio_config)
}
