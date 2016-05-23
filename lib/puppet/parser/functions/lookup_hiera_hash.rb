module Puppet::Parser::Functions
  newfunction(:lookup_hiera_hash, :arity => 2, :type => :rvalue,
              :doc => "Lookup a key->value from a Hiera hash") do |args|
    hash_name = args[0]
    key_name = args[1]
    unless hash_name.is_a?(String) and key_name.is_a?(String)
      raise Puppet::ParseError, "The hash name and the key name must be given as strings."
    end
    if defined? call_function
      hash = call_function('hiera', [hash_name])
    else
      hash = function_hiera([hash_name])
    end
    unless hash.is_a?(Hash)
      raise Puppet::ParseError, "The value Hiera returned for #{hash_name} is not a Hash."
    end
    unless hash.key?(key_name)
      raise Puppet::ParseError, "The Hiera hash #{hash_name} does not contain key #{key_name}."
    end
    return hash[key_name]
  end
end
