# == Class: tripleo::config
#
# Configure services with Puppet
#
# === Parameters:
#
# [*configs*]
#   (optional) Configuration to inject.
#   Should be an hash.
#   Default to lookup('param_config', {})
#
# [*providers*]
#   (optional) Filter the providers we want
#   to use for config.
#   Should be an array.
#   Default to lookup('param_providers', Array[String], 'deep', [])
#
class tripleo::config(
  $configs   = lookup('param_config', {}),
  $providers = lookup('param_providers', Array[String], 'deep', []),
) {

  if ! empty($configs) {
    # Allow composable services to load their own configurations.
    # Each service can load its config options by using this form:
    #
    # puppet_config:
    #   param_config:
    #     'aodh_config':
    #       DEFAULT:
    #         foo: fooValue
    #         bar: barValue
    $configs.each |$provider, $sections| {
      if empty($providers) or ($provider in $providers) {
        $sections.each |$section, $params| {
          $params.each |$param, $value| {
            create_resources($provider, {"${section}/${param}" => {'value' => $value }})
          }
        }
      }
    }
  }

}
