require 'fileutils'

module Puppet::Parser::Functions
  newfunction(:write_package_names, :doc => "Write package names which are managed via this puppet run to a file.") do |arg|
    if arg[0].class == String
      begin
        output_file = arg[0]
        packages = catalog.resources.collect { |r| r.title if r.type == 'Package' }.compact
        FileUtils.mkdir_p(File.dirname(output_file))
        File.open(output_file, 'w') do |f|
            packages.each do |pkg_name|
                f.write(pkg_name + "\n")
            end
        end
      rescue JSON::ParserError
        raise Puppet::ParseError, "Syntax error: #{arg[0]} is invalid"
      end
    else
      raise Puppet::ParseError, "Syntax error: #{arg[0]} is not a String"
    end
  end
end
