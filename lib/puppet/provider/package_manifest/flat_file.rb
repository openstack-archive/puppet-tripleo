
require 'set'


Puppet::Type.type(:package_manifest).provide(:flat_file) do

  desc "Write package manifest to a flat file"

  def exists?
    # exists? is always run before create, so we can create package list here
    @packages = resource.catalog.resources.collect { |r|
        r.name if r.type == :package
    }.compact.sort

    exists = File.exist?(resource[:path])
    if exists
      new_content = Set.new @packages
      old_content = Set.new(
        File.open(resource[:path], 'r').each_line.collect{ |pkg| pkg.strip() }
      )
      exists = new_content == old_content
    end
    exists
  end

  def create
    FileUtils.mkdir_p(File.dirname(resource[:path]))
    File.open(resource[:path], 'w') do |f|
      @packages.each do |pkg_name|
        f.puts(pkg_name)
      end
    end
  end

  def destroy
    File.delete(resource[:path])
  end

end
