Puppet::Functions.create_function(:add_brackets) do
  dispatch :add_brackets do
    param  'String', :odl_ip
  end

  def add_brackets(odl_ip)
    if odl_ip =~ /\[.*\]/
      return odl_ip
    else
      bracketed_ip = "[#{odl_ip}]"
      return bracketed_ip
    end
  end
end
