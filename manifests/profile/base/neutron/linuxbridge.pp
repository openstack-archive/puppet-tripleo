# == Class: tripleo::profile::base::neutron::linuxbridge
#
# Neutron linuxbridge agent profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templatee
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::linuxbridge(
    $step           = Integer(hiera('step')),
) {
    include ::tripleo::profile::base::neutron

    if $step >= 5 {
        include ::neutron::agents::ml2::linuxbridge
    }
}
