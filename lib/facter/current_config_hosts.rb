require 'tempfile'

def get_auth(component)
  provider = Object.const_get "Puppet::Provider::#{component.capitalize}"
  auth_func = "#{component}_credentials"
  if provider.respond_to?(auth_func)
    begin
      q = provider.send(auth_func)
    rescue Puppet::Error
      q = {}
    end
    authenv = {
      'OS_AUTH_URL'     => q['auth_url'],
      'OS_USERNAME'     => q['username'],
      'OS_PROJECT_NAME' => q['project_name'],
      'OS_PASSWORD'     => q['password']
    }
    if q.key?('region_name')
      authenv['OS_REGION_NAME'] = q['region_name']
    end
    authenv
  end
end

def get_live_value_from_auth(component)
  # The path is correct for this tripleo version.
  provider_file = "/etc/puppet/modules/#{component}/lib/puppet/provider/#{component}.rb"
  if File.exists?(provider_file)
    require_relative(provider_file)
    auth_env = get_auth(component)
    host = if auth_env
             Facter::Core::Execution.with_env(auth_env) do
               # We want to find if the current host value is the fqdn
               # or the hostname.  We are sure that it will be at
               # least the hostname so the grep will work.
               Facter::Core::Execution.execute(
                 "#{component} agent-list -c host -f value 2>/dev/null | grep #{Facter.value(:hostname)} 2>/dev/null",
                 {:on_fail => ''}
               ).split("\n").first
             end
           end
    host || ''
  end
end

def get_nova_live_value
  Tempfile.open('get-nova-host') do |nova_stdin|
    File.open(nova_stdin, 'w') do |nova_cmd|
      nova_cmd.puts("import nova.conf\nprint nova.conf.CONF.host")
    end
    Facter::Core::Execution.execute("nova-manage shell python 2>/dev/null < #{nova_stdin.path} | sed -e 's/^[> ]*//'")
  end
end

['nova', 'neutron'].each do |component|
  Facter.add("current_#{component}_host") do
    confine kernel: 'Linux'
    setcode do
      if component == 'nova'
        get_nova_live_value.strip
      else
        get_live_value_from_auth(component).strip
      end
    end
  end
end
