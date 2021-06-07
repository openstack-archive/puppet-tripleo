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
# [*reopen_on_truncate*]
#   (Optional) String. Set all rsyslog imfile reopenOnTruncate parameters
#   unless it is already specified in hiera
#   Defaults to undef
#
define tripleo::profile::base::logging::rsyslog::file_input (
  $sources = hiera("tripleo_logging_sources_${title}", undef),
  $default_startmsg = '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+ [0-9]+)? (DEBUG|INFO|WARNING|ERROR) ',
  Optional[Enum['on','off']] $reopen_on_truncate = undef
) {
  if $sources {
    $sources_array = Array($sources, true)
    $rsyslog_sources = $sources_array.reduce([]) |$memo, $config| {
      if ! $config['startmsg.regex'] {
        $record = $config + {'startmsg.regex' => $default_startmsg}
      } else {
        $record = $config
      }

      if ! $config['reopenOnTruncate'] {
        if $reopen_on_truncate {
          $record2 = $record + {'reopenOnTruncate' => $reopen_on_truncate}
        } else {
          $record2 = $record
        }
      } else {
        $record2 = $record
      }

      $memo + [$record2]
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
