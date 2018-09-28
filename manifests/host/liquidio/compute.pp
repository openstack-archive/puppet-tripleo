# == Class: tripleo::host::liquidio::compute
#
# LiquidioCompute node Configuration
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*controller_node_ip*]
#   (Optional)  controller node ip, contains either odl,
#   ovn or openstack controller ip.
#
# [*tenant_subnet*]
#   (required) Tenant network's ip of the compute node
#   Defaults to  hiera('tenant')
#
# [*tenant_network_type*]
#   (required) Type of tenant networks to be configured
#   Defaults to hiera('neutron::plugins::ml2::tenant_network_types')
#
# [*vf_nums*]
#   (required) Number of VFs to be created on the node
#
# [*configure_mode*]
#   (required) Configuration mode for the current Deployment
#
# [*enable_bonding*]
#   (required) Enable Bonding on Liquidio interfaces.
#   Defaults to true
#
# [*bonding_options*]
#   (required) Bonding optioned supported by Liquidio
#
# [*provider_mappings*]
#   (optional) used by Liquidio service only when bonding
#   is disabled, input format is <extrenal-network-name>:interface
#
# [*opendaylight_api_vip*]
#   (optional) used by Liquidio service to communicate with ODL Controller
#   Defaults to hiera('opendaylight_api_vip')
#
# [*ovn_dbs_vip*]
#   (optional) used by Liquidio service to communicate with OVN Controller
#   Defaults to hiera('ovn_dbs_vip')
#
# [*controller_virtual_ip*]
#   (required) used by Liquidio service to communicate with Controller
#   Defaults to hiera('controller_virtual_ip')
#
# [*pci_passthrough*]
#   (required) used by Liquidio service 
#   Defaults to hiera('nova::compute::pci::passthrough')

class tripleo::host::liquidio::compute (
  $vf_nums,
  $configure_mode,
  $bonding_options,
  $enable_bonding,
  $provider_mappings,
  $tenant_subnet         = hiera('tenant_subnet'),
  $step                  = Integer(hiera('step')),
  $opendaylight_api_vip  = hiera('opendaylight_api_vip', undef),
  $ovn_dbs_vip           = hiera('ovn_dbs_vip', undef),
  $controller_virtual_ip = hiera('controller_virtual_ip', undef),
  $pci_passthrough       = hiera('nova::compute::pci::passthrough', undef),
) {

    if $step >= 5 {
        case $configure_mode {

          'ml2-odl': { $controller_node_ip = $opendaylight_api_vip }
          'ml2-ovn': { $controller_node_ip = $ovn_dbs_vip }
          default  : { $controller_node_ip = $controller_virtual_ip }

        }

        if !$controller_node_ip {
            fail("No controller node ip set for mode '${configure_mode}'")
        }

        liquidio_config {
            'main/controller_node':   value => $controller_node_ip;
            'main/tenant_ip':         value => $tenant_subnet;
            'main/vf_num':            value => $vf_nums;
            'main/configure_mode':    value => $configure_mode;
            'main/enable_bonding':    value => $enable_bonding;
            'main/bonding_options':   value => $bonding_options;
            'main/provider_mappings': value => $provider_mappings;
            'main/pci_passthrough':   value => $pci_passthrough;
            'main/status':            value => 'install-completed';
        }
        service { 'liquidio-compute-service':
          ensure => running,
          name   => 'liquidio-compute-service',
          enable => true,
        }
    }
  }
