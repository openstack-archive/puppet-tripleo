# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::pacemaker::database::mysql
#
# MySQL with Pacemaker profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('mysql_short_bootstrap_node_name')
#
# [*bind_address*]
#   (Optional) The address that the local mysql instance should bind to.
#   Defaults to $::hostname
#
# [*ca_file*]
#   (Optional) The path to the CA file that will be used for the TLS
#   configuration. It's only used if internal TLS is enabled.
#   Defaults to undef
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate
#   it will create. Note that the certificate nickname must be 'mysql' in
#   the case of this service.
#   Example with hiera:
#     tripleo::profile::base::database::mysql::certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "mysql/<overcloud controller fqdn>"
#   Defaults to hiera('tripleo::profile::base::database::mysql::certificate_specs', {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*gmcast_listen_addr*]
#   (Optional) This variable defines the address on which the node listens to
#   connections from other nodes in the cluster.
#   Defaults to hiera('mysql_bind_host')
#
# [*innodb_flush_log_at_trx_commit*]
#   (Optional) Disk flush behavior for MySQL under Galera.  A value of
#   '1' indicates flush to disk per transaction.   A value of '2' indicates
#   flush to disk every second, flushing all unflushed transactions in
#   one step.
#   Defaults to hiera('innodb_flush_log_at_trx_commit', '1')
#
# [*cipher_list*]
#   (Optional) When enable_internal_tls is true, defines the list of allowed
#   ciphers for the mysql server and Galera (including SST).
#   Defaults to '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES:!SSLv3:!TLSv1'
#
# [*gcomm_cipher*]
#   (Optional) When enable_internal_tls is true, defines the cipher
#   used by Galera for the gcomm replication traffic.
#   Defaults to 'AES128-SHA256'
#
# [*sst_tls_cipher*]
#   (Optional) When enable_internal_tls is true, defines the list of
#   ciphers that the socat may use to tunnel SST connections. Deprecated,
#   now socat is configured based on option cipher_list.
#   Defaults to undef
#
# [*sst_tls_options*]
#   (Optional) When enable_internal_tls is true, defines additional
#   parameters to be passed to socat for tunneling SST connections.
#   Defaults to undef
#
# [*ipv6*]
#   (Optional) Whether to deploy MySQL on IPv6 network.
#   Defaults to str2bool(hiera('mysql_ipv6', false))
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
class tripleo::profile::pacemaker::database::mysql (
  $bootstrap_node                 = hiera('mysql_short_bootstrap_node_name'),
  $bind_address                   = $::hostname,
  $ca_file                        = undef,
  $cipher_list                    = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES:!SSLv3:!TLSv1',
  $gcomm_cipher                   = 'AES128-SHA256',
  $certificate_specs              = hiera('tripleo::profile::base::database::mysql::certificate_specs', {}),
  $enable_internal_tls            = hiera('enable_internal_tls', false),
  $gmcast_listen_addr             = hiera('mysql_bind_host'),
  $innodb_flush_log_at_trx_commit = hiera('innodb_flush_log_at_trx_commit', '1'),
  $sst_tls_cipher                 = undef,
  $sst_tls_options                = undef,
  $ipv6                           = str2bool(hiera('mysql_ipv6', false)),
  $step                           = Integer(hiera('step')),
  $pcs_tries                      = hiera('pcs_tries', 20),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  # FQDN are lowercase in /etc/hosts, so are pacemaker node names
  $galera_node_names_lookup = downcase(hiera('mysql_short_node_names', $::hostname))
  $galera_fqdns_names_lookup = downcase(hiera('mysql_node_names', $::hostname))

  if is_array($galera_node_names_lookup) {
    $galera_nodes_count = length($galera_node_names_lookup)
    $galera_nodes = join($galera_fqdns_names_lookup, ',')
    $galera_name_pairs = zip($galera_node_names_lookup, $galera_fqdns_names_lookup)
  } else {
    $galera_nodes_count = 1
    $galera_nodes = $galera_node_names_lookup
    $galera_name_pairs = [[$galera_node_names_lookup, $galera_fqdns_names_lookup]]
  }

  # NOTE(jaosorior): The usage of cluster_host_map requires resource-agents-3.9.5-82.el7_3.11
  $processed_galera_name_pairs = $galera_name_pairs.map |$pair| { join($pair, ':') }
  $cluster_host_map = join($processed_galera_name_pairs, ';')

  if $enable_internal_tls {
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']
    $sst_tls = {
      'tcert' => $tls_certfile,
      'tkey' => $tls_keyfile,
    }
    if $ca_file {
      $tls_ca_options = "socket.ssl_ca=${ca_file}"
      $sst_tca = { 'tca' => $ca_file }
    } else {
      $tls_ca_options = ''
      $sst_tca = {}
    }
    $tls_options = "socket.ssl_key=${tls_keyfile};socket.ssl_cert=${tls_certfile};socket.ssl_cipher=${gcomm_cipher};${tls_ca_options};"
    $wsrep_sst_method = 'rsync_tunnel'
    if $ipv6 {
      $sst_ipv6 = 'pf=ip6'
    } else {
      $sst_ipv6 = undef
    }
    if defined(sst_tls_cipher) {
      warning('The sst_tls_cipher parameter is deprecated, use cipher_list')
      $sst_cipher = $sst_tls_cipher
    } else {
      $sst_cipher = $cipher_list
    }
    $all_sst_options = ["cipher=${sst_cipher}", $sst_tls_options, $sst_ipv6]
    $sst_sockopt = {
      'sockopt' => join(delete_undef_values($all_sst_options), ',')
    }
    $mysqld_options_sst = { 'sst' => merge($sst_tls, $sst_tca, $sst_sockopt) }
  } else {
    $tls_options = ''
    $wsrep_sst_method = 'rsync'
    $mysqld_options_sst = {}
  }

  $mysqld_options_mysqld = {
    'mysqld' => {
      'skip-name-resolve'              => '1',
      'binlog_format'                  => 'ROW',
      'default-storage-engine'         => 'innodb',
      'innodb_autoinc_lock_mode'       => '2',
      'innodb_locks_unsafe_for_binlog' => '1',
      'innodb_file_per_table'          => 'ON',
      'innodb_flush_log_at_trx_commit' => $innodb_flush_log_at_trx_commit,
      'query_cache_size'               => '0',
      'query_cache_type'               => '0',
      'bind-address'                   => $bind_address,
      'max_connections'                => hiera('mysql_max_connections'),
      'open_files_limit'               => '-1',
      'wsrep_on'                       => 'ON',
      'wsrep_provider'                 => '/usr/lib64/galera/libgalera_smm.so',
      'wsrep_cluster_name'             => 'galera_cluster',
      'wsrep_cluster_address'          => "gcomm://${galera_nodes}",
      'wsrep_slave_threads'            => '1',
      'wsrep_certify_nonPK'            => '1',
      'wsrep_debug'                    => '0',
      'wsrep_convert_LOCK_to_trx'      => '0',
      'wsrep_retry_autocommit'         => '1',
      'wsrep_auto_increment_control'   => '1',
      'wsrep_drupal_282555_workaround' => '0',
      'wsrep_causal_reads'             => '0',
      'wsrep_sst_method'               => $wsrep_sst_method,
      'wsrep_provider_options'         => "gmcast.listen_addr=tcp://${gmcast_listen_addr}:4567;${tls_options}",
    }
  }

  $mysqld_options = merge($mysqld_options_mysqld, $mysqld_options_sst)

  # since we are configuring rsync for wsrep_sst_method, we ought to make sure
  # it's installed. We only includ this at step 2 since puppet-rsync may be
  # included later and also adds the package resource.
  if $step == 2 {
      if ! defined(Package['rsync']) {
          package {'rsync':}
      }
  }

  # remove_default_accounts parameter will execute some mysql commands
  # to remove the default accounts created by MySQL package.
  # We need MySQL running to run the commands successfully, so better to
  # wait step 2 before trying to run the commands.
  if $step >= 2 and $pacemaker_master {
    $remove_default_accounts = true
  } else {
    $remove_default_accounts = false
  }

  class { '::tripleo::profile::base::database::mysql':
    bootstrap_node          => $bootstrap_node,
    manage_resources        => false,
    remove_default_accounts => $remove_default_accounts,
    mysql_server_options    => $mysqld_options,
    cipher_list             => $cipher_list
  }

  if $step >= 1 and $pacemaker_master and hiera('stack_action') == 'UPDATE' {
    tripleo::pacemaker::resource_restart_flag { 'galera-master':
      subscribe => File['mysql-config-file'],
    } ~> Exec<| title == 'galera-ready' |>
  }

  if $step >= 2 {
    pacemaker::property { 'galera-role-node-property':
      property => 'galera-role',
      value    => true,
      tries    => $pcs_tries,
      node     => $::hostname,
    }
    if $pacemaker_master {
      pacemaker::resource::ocf { 'galera' :
        ocf_agent_name  => 'heartbeat:galera',
        op_params       => 'promote timeout=300s on-fail=block',
        master_params   => '',
        meta_params     => "master-max=${galera_nodes_count} ordered=true",
        resource_params => "additional_parameters='--open-files-limit=16384' enable_creation=true wsrep_cluster_address='gcomm://${galera_nodes}' cluster_host_map='${cluster_host_map}'",
        tries           => $pcs_tries,
        location_rule   => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['galera-role eq true'],
        },
        require         => [Class['::mysql::server'],
                            Pacemaker::Property['galera-role-node-property']],
        notify          => Exec['galera-ready'],
      }
      exec { 'galera-ready' :
        command     => '/usr/bin/clustercheck >/dev/null',
        timeout     => 30,
        tries       => 180,
        try_sleep   => 10,
        environment => ['AVAILABLE_WHEN_READONLY=0'],
        refreshonly => true,
        require     => Exec['create-root-sysconfig-clustercheck'],
      }
      # We add a clustercheck db user and we will switch /etc/sysconfig/clustercheck
      # to it in a later step. We do this only on one node as it will replicate on
      # the other members. We also make sure that the permissions are the minimum necessary
      mysql_user { 'clustercheck@localhost':
        ensure        => 'present',
        password_hash => mysql_password(hiera('mysql_clustercheck_password')),
        require       => Exec['galera-ready'],
      }
      mysql_grant { 'clustercheck@localhost/*.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['PROCESS'],
        table      => '*.*',
        user       => 'clustercheck@localhost',
      }

      # We create databases and users for services at step 2 as well. This ensures
      # Galara is up before those get created
      Exec['galera-ready'] -> Mysql_database<||>
      Exec['galera-ready'] -> Mysql_user<||>
      Exec['galera-ready'] -> Mysql_grant<||>

    }
    # This step is to create a sysconfig clustercheck file with the root user and empty password
    # on the first install only (because later on the clustercheck db user will be used)
    # We are using exec and not file in order to not have duplicate definition errors in puppet
    # when we later set the file to contain the clustercheck data
    exec { 'create-root-sysconfig-clustercheck':
      command => "/bin/echo 'MYSQL_USERNAME=root\nMYSQL_PASSWORD=\'\'\nMYSQL_HOST=localhost\n' > /etc/sysconfig/clustercheck",
      unless  => '/bin/test -e /etc/sysconfig/clustercheck && grep -q clustercheck /etc/sysconfig/clustercheck',
    }
    xinetd::service { 'galera-monitor' :
      bind           => hiera('mysql_bind_host'),
      port           => '9200',
      server         => '/usr/bin/clustercheck',
      per_source     => 'UNLIMITED',
      log_on_success => '',
      log_on_failure => 'HOST',
      flags          => 'REUSE',
      service_type   => 'UNLISTED',
      user           => 'root',
      group          => 'root',
      require        => Exec['create-root-sysconfig-clustercheck'],
    }
  }

  if $step >= 4 or ( $step >= 3 and $pacemaker_master ) {
    # At this stage we are guaranteed that the clustercheck db user exists
    # so we switch the resource agent to use it.
    $mysql_clustercheck_password = hiera('mysql_clustercheck_password')
    file { '/etc/sysconfig/clustercheck' :
      ensure  => file,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      content => "MYSQL_USERNAME=clustercheck\n
MYSQL_PASSWORD='${mysql_clustercheck_password}'\n
MYSQL_HOST=localhost\n",
    }
  }

  if $step >= 5 {
    # We now make sure that the root db password is set to a random one
    # At first installation /root/.my.cnf will be empty and we connect without a root
    # password. On second runs or updates /root/.my.cnf will already be populated
    # with proper credentials. This step happens on every node because this sql
    # statement does not automatically replicate across nodes.
    $mysql_root_password = hiera('mysql::server::root_password')
    $galera_set_pwd = "/bin/touch /root/.my.cnf && \
                      /bin/echo \"UPDATE mysql.user SET Password = PASSWORD('${mysql_root_password}') WHERE user = 'root'; \
                      flush privileges;\" | \
                      /bin/mysql --defaults-extra-file=/root/.my.cnf -u root"
    exec { 'galera-set-root-password':
      command => $galera_set_pwd,
    }
    file { '/root/.my.cnf' :
      ensure  => file,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      content => "[client]
  user=root
  password=\"${mysql_root_password}\"

  [mysql]
  user=root
  password=\"${mysql_root_password}\"",
      require => Exec['galera-set-root-password'],
    }
  }

}
