require 'ipaddr'

# Custom function to convert an IP4/6 address from a string to the
# erlang inet kernel format.
# For example from "172.17.0.16" to {172,17,0,16}
# See http://erlang.org/doc/man/kernel_app.html and http://erlang.org/doc/man/inet.html
# for more information.
module Puppet::Parser::Functions
  newfunction(:ip_to_erl_format, :type => :rvalue, :doc => "Convert an IP address to the erlang inet format.") do |arg|
    if arg[0].class != String
      raise Puppet::ParseError, "Syntax error: #{arg[0]} must be a String"
    end
    ip = IPAddr.new arg[0]
    output = '{'
    if ip.ipv6?
      split_char = ':'
      base = 16
    else
      split_char = '.'
      base = 10
    end
    # to_string() prints the canonicalized form
    ip.to_string().split(split_char).each {
      |x| output += x.to_i(base).to_s + ','
    }
    # Remove the last spurious comma
    output = output.chomp(',')
    output += '}'
    return output
  end
end
