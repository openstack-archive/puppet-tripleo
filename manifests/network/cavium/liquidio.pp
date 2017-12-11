# == Class: tripleo::network::cavium::liquidio
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

class tripleo::network::cavium::liquidio (
  $vf_nums,
  $configure_mode,
  $bonding_options,
  $enable_bonding,
  $provider_mappings,
  $step                  = Integer(hiera('step')),
  $tenant_subnet         = hiera('tenant_subnet'),
  $opendaylight_api_vip  = hiera('opendaylight_api_vip', undef),
  $ovn_dbs_vip           = hiera('ovn_dbs_vip', undef),
  $controller_virtual_ip = hiera('controller_virtual_ip', undef),
) {

  if $step >= 5 {

    $controller_node_ip = $configure_mode ? {
      'ml2-odl' => $opendaylight_api_vip,
      'ml2-ovn' => $ovn_dbs_vip,
      Default   => $controller_virtual_ip,
    }

    if !$controller_node_ip {
      fail("No controller node ip set for mode '${configure_mode}'")
    }

    $lioconfig = @("LIOCONFIG"/L)
    [main]
    controller_node=${controller_node_ip}
    tenant_ip=${tenant_subnet}
    vf_num=${vf_nums}
    configure_mode=${configure_mode}
    enable_bonding=${enable_bonding}
    bonding_options=${bonding_options}
    provider_mappings=${provider_mappings}
    status=install-completed
    | LIOCONFIG

    file{ '/etc/liquidio.conf':
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0664',
      content => $lioconfig
    }

    service { 'liquidio-compute-service':
      ensure => running,
      name   => 'liquidio-compute-service',
      enable => true,
    }
  }
}
