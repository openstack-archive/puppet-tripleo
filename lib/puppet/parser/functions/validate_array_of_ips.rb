# Custom function to validate an array of ips
# Based on validate_ip_address() in stdlib
module Puppet::Parser::Functions

  newfunction(:validate_array_of_ips) do |argv|

    args = argv[0]

    require "ipaddr"
    rescuable_exceptions = [ ArgumentError ]

    if defined?(IPAddr::InvalidAddressError)
      rescuable_exceptions << IPAddr::InvalidAddressError
    end

    args.each do |arg|
      unless arg.is_a?(String)
        raise Puppet::ParseError, "#{arg.inspect} is not a string."
      end

      begin
        unless IPAddr.new(arg).ipv4? or IPAddr.new(arg).ipv6?
          raise Puppet::ParseError, "#{arg.inspect} is not a valid IP address."
        end
      rescue *rescuable_exceptions
        raise Puppet::ParseError, "#{arg.inspect} is not a valid IP address."
      end
    end

  end

end