require 'puppet-openstack_spec_helper/rake_tasks'

# We disable the unquoted node name check because puppet-pacemaker node
# properies make use of attributes called 'node' and puppet-lint breaks on
# them: https://github.com/rodjek/puppet-lint/issues/501
# We are not using site.pp with nodes so this is safe.
PuppetLint.configuration.send('disable_unquoted_node_name')
