Puppet::Type.type(:service).provide :noop, :parent => :systemd do
  def startcmd
    [ "/bin/true" ]
  end

  def stopcmd
    [ "/bin/true" ]
  end

  def restartcmd
    [ "/bin/true" ]
  end

  def statuscmd
    [ "/bin/true" ]
  end
end
