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
# [*gmcast_listen_addr*]
#   (Optional) This variable defines the address on which the node listens to
#   connections from other nodes in the cluster.
#   Defaults to hiera('mysql_bind_host')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::pacemaker::database::mysql (
  $bootstrap_node     = hiera('mysql_short_bootstrap_node_name'),
  $bind_address       = $::hostname,
  $gmcast_listen_addr = hiera('mysql_bind_host'),
  $step               = hiera('step'),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  # use only mysql_node_names when we land a patch in t-h-t that
  # switches to autogenerating these values from composable services
  # The galera node names need to match the pacemaker node names... so if we
  # want to use FQDNs for this, the cluster will not finish bootstrapping,
  # since all the nodes will be marked as slaves. For now, we'll stick to the
  # short name which is already registered in pacemaker until we get around
  # this issue.
  $galera_node_names_lookup = hiera('mysql_short_node_names', hiera('mysql_node_names', $::hostname))
  if is_array($galera_node_names_lookup) {
    $galera_nodes = downcase(join($galera_node_names_lookup, ','))
  } else {
    $galera_nodes = downcase($galera_node_names_lookup)
  }
  $galera_nodes_count = count(split($galera_nodes, ','))

  $mysqld_options = {
    'mysqld' => {
      'skip-name-resolve'             => '1',
      'binlog_format'                 => 'ROW',
      'default-storage-engine'        => 'innodb',
      'innodb_autoinc_lock_mode'      => '2',
      'innodb_locks_unsafe_for_binlog'=> '1',
      'query_cache_size'              => '0',
      'query_cache_type'              => '0',
      'bind-address'                  => $bind_address,
      'max_connections'               => hiera('mysql_max_connections'),
      'open_files_limit'              => '-1',
      'wsrep_on'                      => 'ON',
      'wsrep_provider'                => '/usr/lib64/galera/libgalera_smm.so',
      'wsrep_cluster_name'            => 'galera_cluster',
      'wsrep_cluster_address'         => "gcomm://${galera_nodes}",
      'wsrep_slave_threads'           => '1',
      'wsrep_certify_nonPK'           => '1',
      'wsrep_max_ws_rows'             => '131072',
      'wsrep_max_ws_size'             => '1073741824',
      'wsrep_debug'                   => '0',
      'wsrep_convert_LOCK_to_trx'     => '0',
      'wsrep_retry_autocommit'        => '1',
      'wsrep_auto_increment_control'  => '1',
      'wsrep_drupal_282555_workaround'=> '0',
      'wsrep_causal_reads'            => '0',
      'wsrep_sst_method'              => 'rsync',
      'wsrep_provider_options'        => "gmcast.listen_addr=tcp://${gmcast_listen_addr}:4567;",
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
  }

  if $step >= 1 and $pacemaker_master and hiera('stack_action') == 'UPDATE' {
    tripleo::pacemaker::resource_restart_flag { 'galera-master':
      subscribe => File['mysql-config-file'],
    }
  }

  if $step >= 2 {
    if $pacemaker_master {
      pacemaker::resource::ocf { 'galera' :
        ocf_agent_name  => 'heartbeat:galera',
        op_params       => 'promote timeout=300s on-fail=block',
        master_params   => '',
        meta_params     => "master-max=${galera_nodes_count} ordered=true",
        resource_params => "additional_parameters='--open-files-limit=16384' enable_creation=true wsrep_cluster_address='gcomm://${galera_nodes}'",
        require         => Class['::mysql::server'],
        before          => Exec['galera-ready'],
      }
      exec { 'galera-ready' :
        command     => '/usr/bin/clustercheck >/dev/null',
        timeout     => 30,
        tries       => 180,
        try_sleep   => 10,
        environment => ['AVAILABLE_WHEN_READONLY=0'],
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

    }
    # This step is to create a sysconfig clustercheck file with the root user and empty password
    # on the first install only (because later on the clustercheck db user will be used)
    # We are using exec and not file in order to not have duplicate definition errors in puppet
    # when we later set the the file to contain the clustercheck data
    exec { 'create-root-sysconfig-clustercheck':
      command => "/bin/echo 'MYSQL_USERNAME=root\nMYSQL_PASSWORD=\'\'\nMYSQL_HOST=localhost\n' > /etc/sysconfig/clustercheck",
      unless  => '/bin/test -e /etc/sysconfig/clustercheck && grep -q clustercheck /etc/sysconfig/clustercheck',
    }
    xinetd::service { 'galera-monitor' :
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
