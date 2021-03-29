# This adds to ssl profile hash a proper value of "caCertFile" key for "caCertFileContent" key.
#
# Given:
#   ssl_profiles = [{"name": "test", "caCertFileContent": "cert content", ...}, ...]
#   cert_dir = "/etc/pki/tls/certs/"
# Returns:
#   ssl_profiles = [
#     {"name": "test",
#      "caCertFileContent": "cert content",
#      "caCertFile": "/etc/pki/tls/certs/CA_test.pem",
#      ... },
#     ...
#   ]
Puppet::Functions.create_function(:qdr_ssl_certificate) do

  dispatch :qdr_ssl_certificate do
    param 'Array', :ssl_profiles
    param 'String', :cert_dir
    return_type 'Array'
  end

  def qdr_ssl_certificate(ssl_profiles, cert_dir)
    processed_profiles = Array.new
    ssl_profiles.each do |profile|
      if profile.key?("caCertFileContent")
        processed = profile.clone
        # create certificate path
        path = File.join(cert_dir, "CA_#{processed["name"]}.pem")
        # update profile
        processed["caCertFile"] = path
        processed_profiles.append(processed)
      else
        processed_profiles.append(profile)
      end
    end
    return processed_profiles
  end

end
