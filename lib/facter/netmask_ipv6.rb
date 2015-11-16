require 'ipaddr'

def netmask6(value)
  if value
    ip = IPAddr.new('::0').mask(value)
    ip.inspect.split('/')[1].gsub('>', '')
  end
end

if Facter.value('facterversion')[0].to_i < 3
  Facter::Util::IP.get_interfaces.each do |interface|
    Facter.add('netmask6_' + Facter::Util::IP.alphafy(interface)) do
      setcode do
        tmp = []
        regex = %r{inet6\s+.*\s+(?:prefixlen)\s+(\d+)}x
        output_int = Facter::Util::IP.get_output_for_interface_and_label(interface, 'netmask6')

        output_int.each_line do |line|
          prefixlen = nil
          matches = line.match(regex)
          prefixlen = matches[1] if matches

          if prefixlen
            value = netmask6(prefixlen)
            tmp.push(value)
          end
        end

        tmp.shift if tmp
      end
    end
  end

  Facter.add('netmask6') do
    setcode do
      prefixlen = nil
      regex = %r{#{Facter.value(:ipaddress6)}.*?(?:prefixlen)\s*(\d+)}x

      String(Facter::Util::IP.exec_ifconfig(['2>/dev/null'])).split(/\n/).collect do |line|
        matches = line.match(regex)
        prefixlen = matches[1] if matches
      end

      netmask6(prefixlen) if prefixlen
    end
  end
end
