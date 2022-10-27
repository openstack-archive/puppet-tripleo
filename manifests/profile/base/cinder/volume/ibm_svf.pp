#
# == Class: tripleo::profile::base::cinder::volume::ibm_svf
#
# Cinder Volume IBM Spectrum Virtualize family (Svf) profile for tripleo
#
# === Parameters
#
# [*backend_name*]
#   (Optional) List of names given to the Cinder backend stanza.
#   Defaults to lookup('cinder::backend:ibm_svf::volume_backend_name', undef, undef,
#   ['tripleo_ibm_svf'])
#
# [*multi_config*]
#   (Optional) A config hash when multiple backends are used.
#   Defaults to lookup('cinder::backend::ibm_svf::volume_multi_config', undef, undef, {})
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::cinder::volume::ibm_svf (
  $backend_name = lookup('cinder::backend::ibm_svf::volume_backend_name', undef, undef, ['tripleo_ibm_svf']),
  $multi_config = lookup('cinder::backend::ibm_svf::volume_multi_config', undef, undef, {}),
  $step         = Integer(lookup('step')),
) {
  include tripleo::profile::base::cinder::volume
  # NOTE: Svf was earlier called as storwize/svc driver, so the cinder
  # configuration parameters were named accordingly.
  if $step >= 4 {
    $backend_defaults = {
      'CinderSvfAvailabilityZone'    => lookup('cinder::backend::ibm_svf::backend_availability_zone', undef, undef, undef),
      'CinderSvfSanIp'               => lookup('cinder::backend::ibm_svf::san_ip', undef, undef, undef),
      'CinderSvfSanLogin'            => lookup('cinder::backend::ibm_svf::san_login', undef, undef, undef),
      'CinderSvfSanPassword'         => lookup('cinder::backend::ibm_svf::san_password', undef, undef, undef),
      'CinderSvfAllowTenantQos'      => lookup('cinder::backend::ibm_svf::storwize_svc_allow_tenant_qos', undef, undef, undef),
      'CinderSvfConnectionProtocol'  => lookup('cinder::backend::ibm_svf::storwize_svc_connection_protocol', undef, undef, undef),
      'CinderSvfIscsiChapEnabled'    => lookup('cinder::backend::ibm_svf::storwize_svc_iscsi_chap_enabled', undef, undef, undef),
      'CinderSvfRetainAuxVolume'     => lookup('cinder::backend::ibm_svf::storwize_svc_retain_aux_volume', undef, undef, undef),
      'CinderSvfVolumePoolName'      => lookup('cinder::backend::ibm_svf::storwize_svc_volpool_name', undef, undef, undef),
    }

    any2array($backend_name).each |String $backend| {
      $backend_config = merge($backend_defaults, pick($multi_config[$backend], {}))

      create_resources('cinder::backend::ibm_svf', { $backend => delete_undef_values({
        'backend_availability_zone'         => $backend_config['CinderSvfAvailabilityZone'],
        'san_ip'                            => $backend_config['CinderSvfSanIp'],
        'san_login'                         => $backend_config['CinderSvfSanLogin'],
        'san_password'                      => $backend_config['CinderSvfSanPassword'],
        'storwize_svc_allow_tenant_qos'     => $backend_config['CinderSvfAllowTenantQos'],
        'storwize_svc_connection_protocol'  => $backend_config['CinderSvfConnectionProtocol'],
        'storwize_svc_iscsi_chap_enabled'   => $backend_config['CinderSvfIscsiChapEnabled'],
        'storwize_svc_retain_aux_volume'    => $backend_config['CinderSvfRetainAuxVolume'],
        'storwize_svc_volpool_name'         => $backend_config['CinderSvfVolumePoolName'],
      })})
    }
  }

}
