# This is used to look up a list of service-specific rsyslogd configurations
# in the hiera data provided by THT.
#
# [*sources*]
#   (Optional) List of hashes. Contains configuration of file inputs for given service.
#   Defaults to hiera("tripleo_logging_sources_${title}", undef)
#
# [*default_startmsg*]
#   (Optional) String. Default POSIX ERE for start of log record. The default enables to forward
#   multiline tracebacks for most of OpenStack services. It can be overridden either by this
#   parameter for all file inputs or in each file input separately in THT parameters
#   tripleo_logging_sources_<service name>.
#   Defaults to '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+ [0-9]+)? (DEBUG|INFO|WARNING|ERROR) '
#
define tripleo::profile::base::logging::rsyslog::file_input (
  $sources = hiera("tripleo_logging_sources_${title}", undef),
  $default_startmsg = '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+ [0-9]+)? (DEBUG|INFO|WARNING|ERROR) '
) {
  if $sources {
    $rsyslog_sources = $sources.reduce([]) |$memo, $config| {
      if ! $config['startmsg.regex'] {
        $record = $config + {'startmsg.regex' => $default_startmsg}
      } else {
        $record = $config
      }
      $memo + [$record]
    }

    $rsyslog_sources.each |$config| {
      rsyslog::component::input{ "${title}_${config['tag']}":
        priority => $::rsyslog::input_priority,
        target   => $::rsyslog::target_file,
        confdir  => $::rsyslog::confdir,
        type     => 'imfile',
        config   => $config
      }
    }
  }
}
