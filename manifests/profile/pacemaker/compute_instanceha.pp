# == Class: tripleo::profile::pacemaker::compute_instanceha
#
# Configures Compute nodes for Instance HA
#
# === Parameters:
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to lookup('pcs_tries', undef, undef, 20)
#
# [*enable_instanceha*]
#  (Optional) Boolean driving the Instance HA controlplane configuration
#  Defaults to false
#
class tripleo::profile::pacemaker::compute_instanceha (
  $step              = Integer(lookup('step')),
  $pcs_tries         = lookup('pcs_tries', undef, undef, 20),
  $enable_instanceha = lookup('tripleo::instanceha', undef, undef, false),
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
