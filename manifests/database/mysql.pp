#
# Copyright (C) 2015 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless optional by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::database::mysql
#
# Configure a MySQL for TripleO with or without HA.
#
# === Parameters
#
# [*bind_address*]
#   (optional) IP to bind MySQL daemon.
#   Defaults to undef
#
# [*mysql_root_password*]
#   (optional) MySQL root password.
#   Defaults to 'secrete'
#
# [*mysql_sys_maint_password*]
#   (optional) The MySQL debian-sys-maint password.
#   Debian only parameter.
#   Defaults to 'sys-maint'
#
# [*galera_clustercheck_dbpassword*]
#   (optional) The MySQL password for Galera cluster check
#   Defaults to 'password'
#
# [*galera_clustercheck_dbuser*]
#   (optional) The MySQL username for Galera cluster check (using monitoring database)
#   Defaults to 'clustercheck'
#
# [*galera_clustercheck_ipaddress*]
#   (optional) The name or ip address of host running monitoring database (clustercheck)
#   Defaults to undef
#
# [*galera_gcache*]
#   (optional) Size of the Galera gcache
#   wsrep_provider_options, for master/slave mode
#   Defaults to '1G'
#
# [*galera_master*]
#   (optional) Hostname or IP of the Galera master node, databases and users
#   resources are created on this node and propagated on the cluster.
#   Defining to false means we disable MySQL HA and run a single node setup.
#   Defaults to false
#
# [*controller_host*]
#   (optional) Array of internal ip of the controller nodes.
#   They need access to all OpenStack databases.
#   Defaults to false
#
# [*database_host*]
#   (optional) Array of internal ip of the database nodes.
#   Used to boostrap Galera cluster.
#   Defaults to false
#
# [*ceilometer_database_connection*]
#   (optional) URL to connect at Ceilometer database.
#   Example: 'mysql://user:password@host/database'
#   Defaults to undef
#
# [*cinder_database_connection*]
#   (optional) URL to connect at Cinder database.
#   Example: 'mysql://user:password@host/database'
#   Defaults to undef
#
# [*glance_database_connection*]
#   (optional) URL to connect at Glance database.
#   Example: 'mysql://user:password@host/database'
#   Defaults to undef
#
# [*heat_database_connection*]
#   (optional) URL to connect at Heat database.
#   Example: 'mysql://user:password@host/database'
#   Defaults to undef
#
# [*keystone_database_connection*]
#   (optional) URL to connect at Keystone database.
#   Example: 'mysql://user:password@host/database'
#   Defaults to undef
#
# [*neutron_database_connection*]
#   (optional) URL to connect at Neutron database.
#   Example: 'mysql://user:password@host/database'
#   Defaults to undef
#
# [*nova_database_connection*]
#   (optional) URL to connect at Nova database.
#   Example: 'mysql://user:password@host/database'
#   Defaults to undef
#
class tripleo::database::mysql (
  $bind_address                   = undef,
  $mysql_root_password            = 'secrete',
  $mysql_sys_maint_password       = 'sys-maint',
  $galera_clustercheck_dbpassword = 'secrete',
  $galera_clustercheck_dbuser     = 'clustercheck',
  $galera_clustercheck_ipaddress  = undef,
  $galera_gcache                  = '1G',
  $galera_master                  = false,
  $controller_host                = false,
  $database_host                  = false,
  $ceilometer_database_connection = undef,
  $cinder_database_connection     = undef,
  $glance_database_connection     = undef,
  $heat_database_connection       = undef,
  $keystone_database_connection   = undef,
  $neutron_database_connection    = undef,
  $nova_database_connection       = undef,
) {

  include ::xinetd

  $gcomm_definition = inline_template('<%= @database_host.join(",") + "?pc.wait_prim=no" -%>')

  # If HA enabled
  if $galera_master {
    # Specific to Galera master node
    if $::hostname == $galera_master {
      mysql_database { 'monitoring':
        ensure  => 'present',
        charset => 'utf8',
        collate => 'utf8_unicode_ci',
        require => File['/root/.my.cnf'],
      }
      mysql_user { "${galera_clustercheck_dbuser}@localhost":
        ensure        => 'present',
        password_hash => mysql_password($galera_clustercheck_dbpassword),
        require       => File['/root/.my.cnf'],
      }
      mysql_grant { "${galera_clustercheck_dbuser}@localhost/monitoring":
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => 'monitoring.*',
        user       => "${galera_clustercheck_dbuser}@localhost",
      }
      Database_user<<| |>>
    } else {
      # NOTE(sileht): Only the master must create the password
      # into the database, slave nodes must just use the password.
      # The one in the database have been retrieved via galera.
      file { "${::root_home}/.my.cnf":
        content => "[client]\nuser=root\nhost=localhost\npassword=${mysql_root_password}\n",
        owner   => 'root',
        mode    => '0600',
      }
    }

    # Specific to Red Hat or Debian systems
    case $::osfamily {
      'RedHat': {
        $mysql_server_package_name = 'mariadb-galera-server'
        $mysql_client_package_name = 'mariadb'
        $wsrep_provider = '/usr/lib64/galera/libgalera_smm.so'
        $mysql_server_config_file = '/etc/my.cnf'
        $mysql_init_file = '/usr/lib/systemd/system/mysql-bootstrap.service'

        if $::hostname == $galera_master {
          $mysql_service_name = 'mysql-bootstrap'
        } else {
          $mysql_service_name = 'mariadb'
        }

        # In Red Hat, the package does not perform the mysql db installation.
        # We need to do this manually.
        # Note: in MariaDB repository, package perform this action in post-install,
        # but MariaDB is not packaged for Red Hat / CentOS 7 in MariaDB repository.
        exec { 'bootstrap-mysql':
          command => '/usr/bin/mysql_install_db --rpm --user=mysql',
          unless  => 'test -d /var/lib/mysql/mysql',
          before  => Service['mysqld'],
          require => [Package[$mysql_server_package_name], File[$mysql_server_config_file]],
        }

      }
      'Debian': {
        $mysql_server_package_name = 'mariadb-galera-server'
        $mysql_client_package_name = 'mariadb-client'
        $wsrep_provider = '/usr/lib/galera/libgalera_smm.so'
        $mysql_server_config_file = '/etc/mysql/my.cnf'
        $mysql_init_file = '/etc/init.d/mysql-bootstrap'

        if $::hostname == $galera_master {
          $mysql_service_name = 'mysql-bootstrap'
        } else {
          $mysql_service_name = 'mysql'
        }

        mysql_user { 'debian-sys-maint@localhost':
          ensure        => 'present',
          password_hash => mysql_password($mysql_sys_maint_password),
          require       => File['/root/.my.cnf'],
        }

        file{'/etc/mysql/debian.cnf':
          ensure  => file,
          content => template('tripleo/database/debian.cnf.erb'),
          owner   => 'root',
          group   => 'root',
          mode    => '0600',
          require => Exec['clean-mysql-binlog'],
        }
      }
      default: {
        err "${::osfamily} not supported yet"
      }
    }

    file { $mysql_init_file :
      content => template("tripleo/database/etc_initd_mysql_${::osfamily}"),
      owner   => 'root',
      mode    => '0755',
      group   => 'root',
      notify  => Service['mysqld'],
      before  => Package[$mysql_server_package_name],
    }

    class { '::mysql::server':
      manage_config_file => false,
      config_file        => $mysql_server_config_file,
      package_name       => $mysql_server_package_name,
      service_name       => $mysql_service_name,
      override_options   => {
        'mysqld' => {
          'bind-address' => $bind_address,
        },
      },
      root_password      => $mysql_root_password,
      notify             => Service['xinetd'],
    }

    file { $mysql_server_config_file:
      content => template('tripleo/database/mysql.conf.erb'),
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      notify  => [Service['mysqld'],Exec['clean-mysql-binlog']],
      require => Package[$mysql_server_package_name],
    }

    class { '::mysql::client':
      package_name => $mysql_client_package_name,
    }

    # Haproxy http monitoring
    augeas { 'mysqlchk':
      context => '/files/etc/services',
      changes => [
        'ins service-name after service-name[last()]',
        'set service-name[last()] "mysqlchk"',
        'set service-name[. = "mysqlchk"]/port 9200',
        'set service-name[. = "mysqlchk"]/protocol tcp',
      ],
      onlyif  => 'match service-name[. = "mysqlchk"] size == 0',
      notify  => [ Service['xinetd'], Exec['reload_xinetd'] ],
    }
    file {
      '/etc/xinetd.d/mysqlchk':
        content => template('tripleo/database/mysqlchk.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/usr/bin/clustercheck'],
        notify  => [ Service['xinetd'], Exec['reload_xinetd'] ];
      '/usr/bin/clustercheck':
        ensure  => present,
        content => template('tripleo/database/clustercheck.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root';
    }

    exec{'clean-mysql-binlog':
      # first sync take a long time
      command     => "/bin/bash -c '/usr/bin/mysqladmin --defaults-file=/root/.my.cnf shutdown ; /bin/rm  ${::mysql::params::datadir}/ib_logfile*'",
      path        => '/usr/bin',
      notify      => Service['mysqld'],
      refreshonly => true,
      onlyif      => "stat ${::mysql::params::datadir}/ib_logfile0 && test `du -sh ${::mysql::params::datadir}/ib_logfile0 | cut -f1` != '256M'",
    }
  } else {
    # When HA is disabled
    class { '::mysql::server':
      override_options => {
        'mysqld' => {
          'bind-address' => $bind_address,
        },
      },
      root_password    => $mysql_root_password,
    }
  }

  # On master node (when using Galera) or single node (when no HA)
  if $galera_master == $::hostname or ! $galera_master {
    # Create all the database schemas
    $allowed_hosts = ['%',$controller_host]
    $keystone_dsn = split($keystone_database_connection, '[@:/?]')
    class { '::keystone::db::mysql':
      user          => $keystone_dsn[3],
      password      => $keystone_dsn[4],
      host          => $keystone_dsn[5],
      dbname        => $keystone_dsn[6],
      allowed_hosts => $allowed_hosts,
    }
    $glance_dsn = split($glance_database_connection, '[@:/?]')
    class { '::glance::db::mysql':
      user          => $glance_dsn[3],
      password      => $glance_dsn[4],
      host          => $glance_dsn[5],
      dbname        => $glance_dsn[6],
      allowed_hosts => $allowed_hosts,
    }
    $nova_dsn = split($nova_database_connection, '[@:/?]')
    class { '::nova::db::mysql':
      user          => $nova_dsn[3],
      password      => $nova_dsn[4],
      host          => $nova_dsn[5],
      dbname        => $nova_dsn[6],
      allowed_hosts => $allowed_hosts,
    }
    $neutron_dsn = split($neutron_database_connection, '[@:/?]')
    class { '::neutron::db::mysql':
      user          => $neutron_dsn[3],
      password      => $neutron_dsn[4],
      host          => $neutron_dsn[5],
      dbname        => $neutron_dsn[6],
      allowed_hosts => $allowed_hosts,
    }
    $cinder_dsn = split($cinder_database_connection, '[@:/?]')
    class { '::cinder::db::mysql':
      user          => $cinder_dsn[3],
      password      => $cinder_dsn[4],
      host          => $cinder_dsn[5],
      dbname        => $cinder_dsn[6],
      allowed_hosts => $allowed_hosts,
    }
    $heat_dsn = split($heat_database_connection, '[@:/?]')
    class { '::heat::db::mysql':
      user          => $heat_dsn[3],
      password      => $heat_dsn[4],
      host          => $heat_dsn[5],
      dbname        => $heat_dsn[6],
      allowed_hosts => $allowed_hosts,
    }
    $ceilometer_dsn = split($ceilometer_database_connection, '[@:/?]')
    class { '::ceilometer::db::mysql':
      user          => $ceilometer_dsn[3],
      password      => $ceilometer_dsn[4],
      host          => $ceilometer_dsn[5],
      dbname        => $ceilometer_dsn[6],
      allowed_hosts => $allowed_hosts,
    }
  }

}
