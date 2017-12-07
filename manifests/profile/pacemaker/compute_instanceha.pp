# == Class: tripleo::profile::pacemaker::compute_instanceha
#
# Configures Compute nodes for Instance HA
#
# === Parameters:
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*enable_instanceha*]
#  (Optional) Boolean driving the Instance HA controlplane configuration
#  Defaults to false
#
class tripleo::profile::pacemaker::compute_instanceha (
  $step              = Integer(hiera('step')),
  $pcs_tries         = hiera('pcs_tries', 20),
  $enable_instanceha = hiera('tripleo::instanceha', false),
) {
  if $step >= 2 and $enable_instanceha {
    pacemaker::property { 'compute-instanceha-role-node-property':
      property => 'compute-instanceha-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
  }
}
