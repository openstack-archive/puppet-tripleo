# Custom function to generate password hash for MariaDB's auth_ed25519
# Input is a regular mariadb user password
# Output is the hashed password as expected by auth_ed25519
Puppet::Functions.create_function(:'mysql_ed25519_password') do
  dispatch :mysql_ed25519_password do
    param 'String', :password
    return_type 'String'
  end

  def mysql_ed25519_password(password)
    # mysql's auth_ed25519 consists in generating a ed25519 public key
    # out of the sha512(password). Unfortunately, there is no native
    # ruby implementation of ed25519's unclamped scalar multiplication
    # just yet, so rely on an binary to get the hash for now.
    python = `(which python3 || which python2 || which python) 2>/dev/null`
    raise Puppet::Error, 'python interpreter not found in path' unless $?.success?
    hashed = `#{python.rstrip()} /etc/puppet/modules/tripleo/files/mysql_ed25519_password.py #{password}`
    raise Puppet::Error, 'generated hash is not 43 bytes long.' unless hashed.length == 43
    return hashed
  end
end
