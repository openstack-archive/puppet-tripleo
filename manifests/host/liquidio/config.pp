# == Class: tripleo::host::liquidio::config
#
# This class is used to manage Liquidio configurations.
#
# === Parameters
#
# [*xxx_config*]
#   (optional) Allow configuration of arbitrary Neutron xxx specific configurations.
#   The value is a hash of neutron_config resources. Example:
#   server_config =>
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#
#   NOTE: { 'DEFAULT/foo': value => 'fooValue'; 'DEFAULT/bar': value => 'barValue'} is invalid.
#
#   In yaml format, Example:
#   server_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
# [*liquidio_config*]
#   (optional) Allow configuration of liquidio.conf configurations.
#
class tripleo::host::liquidio::config (
  $liquidio_config = {}
) {

    validate_hash($liquidio_config)

    create_resources('liquidio_config', $liquidio_config)
}
