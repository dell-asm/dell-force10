require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_settings).provide :dell_ftos do
  desc "Dell Force10 switch provider for switch commands execution."

  #Hard to automatically check if ntp_server "1" is set, but setting again shouldn't cause issues.
  def ntp_server1;  end

  def ntp_server1=(ntp_server1)
    send_cmd("ntp server #{ntp_server1}", :conf)
  end

  def ntp_server2; end

  def ntp_server2=(ntp_server2)
    send_cmd("ntp server #{ntp_server2}", :conf)
    # return txt
  end

  #hostname
  def hostname
    transport.facts['hostname']
  end

  def hostname=(hostname)
    send_cmd("hostname #{hostname}", :conf)
  end

  #logging {ip-address | hostname}
  def syslog_destination
    lines = send_cmd("show running-config |grep logging")
    #Do this select as a sanity check to ensure we aren't getting extra lines that aren't important.
    syslog_txt = lines.select{|x| x.start_with?('logging ')}.first
    syslog_txt.rpartition(' ').last if !syslog_txt.nil?
  end

  def syslog_destination=(syslog_destination)
    send_cmd("logging #{syslog_destination}", :conf)
  end


  def transport
    @transport ||= PuppetX::Force10::Transport.new(Puppet[:certname])
  end

  def send_cmd(command, context='')
    out = ''
    session = transport.session
    if context == :conf
      session.command('conf')
      out = session.command(command)
      session.command('end')
    else
      out = session.command(command)
    end
    if out.include?("Error:")
      Puppet.err("Could not send command #{command}.\nMessage: #{out}")
      return out
    else
      #Remove the prompt text and the command text since those are not important
      out.split("\n").reject do |x| 
        x =~ session.default_prompt || x == command
      end
    end
  end

  #switch spanning-tree protocol
  def spanning_tree_mode; end

  def spanning_tree_mode=(spanning_tree_mode)
    session = transport.session
    existing_protocol = show_protocol(session)
    update_protocol(session,spanning_tree_mode,existing_protocol)
  end

  def show_protocol(session)
    meta_data =  session.command('show running-config') || ''
    result = []
    match_data = /protocol spanning\-tree\s+(\w+)/
    meta_data.split("\n").each do |line|
      stp = line.match(match_data)
      result << stp[1] if stp
    end
    result
  end

  def update_protocol(session, protocol, existing_protocol)
    #Since we are receiving RSTP, PVST
    if protocol.downcase == "none"
      protocol = []
    else
      protocol = protocol.downcase.split(",")
    end
    disable_stp = existing_protocol - protocol
    session.command("configure")
    disable_stp.each do |stp|
      session.command("no protocol spanning-tree #{stp}")
    end
    enable_stp = protocol - existing_protocol
    enable_stp.each do |stp|
      session.command("protocol spanning-tree #{stp}")
      session.command("no disable")
    end
    session.command("end")
  end

end
