#Provider for force10 'CONFIG' Type
#Compares provided configuration MD5 with existing configuration MD5 and so apply the configuration if any change found
#Can use Force option for applying configuration always

require 'puppet/provider/dell_ftos'
require 'digest/md5'
require 'fileutils'

Puppet::Type.type(:force10_config).provide :dell_ftos, :parent => Puppet::Provider do
  desc "Dell Force10 switch provider for configuration updates."
  mk_resource_methods

  def transport
    @transport ||= PuppetX::Force10::Transport.new(Puppet[:certname])
  end

  def send_command(cmd, opts={})
    transport.session.command(cmd, opts) do |line|
      yield line if block_given?
    end
  end

  def run(url, startup_config, force, source_server, source_file_path, copy_to_tftp)
    @source_file_path = source_file_path
    @copy_to_tftp = copy_to_tftp
    @source_server = source_server
    disable_bmp_mode
    if startup_config == :true
      return applyconfig(url,'startup-config', force)
    else
      return applyconfig(url,'running-config',force)
    end
  end

  def disable_bmp_mode
    send_command('enable')
    reload_type = send_command('show reload-type').scan(/Next boot\s*:\s*(\S+)/).flatten.first
    Puppet.debug("Reload Type: #{reload_type}")
    if !reload_type.match(/normal-reload/)
      Puppet.debug("Reload type is not 'normal-reload', updated the reload-type of the switch")
      send_command('conf')
      send_command('reload-type normal-reload')
      send_command('end')
      send_command('write memory')
    end
  end

  def applyconfig(url, config, force)
    txt = ''
    digesttftpfile=''
    digestlocalfile=''
    configexists=true
    startupconfigchanged=false

    copy_files if @copy_to_tftp
    Puppet.debug("URL location before: #{url}")
    url = "tftp://#{@source_server}/#{@copy_to_tftp[1]}"  if @source_server and url.length == 0
    Puppet.debug ("URL location: #{url}, source server: #{@source_server}")

    #delete temporary configuration files if exists
    send_command('delete flash://temp-config no-confirm')
    send_command('delete flash://last-config no-confirm')

    #Calculate MD5 for running configuration, if exists
    localfilecontent  =''
    Puppet.debug("Config name: #{config}")
    if config=='startup-config'
      if transport.session.class.name.include? "Telnet"
        send_command('show file flash://startup-config') do |out|
          localfilecontent<< out
        end
      else
        # In case of SSH 'out' is not returning continuous chunks of the console output
        # SSH 'out' chunks having repeat data i.e. each chunk having data from command output 'starting line'
        # And so clearing localfilecontent in loop, and so taking last output chunk
        send_command('show file flash://startup-config') do |out|
          localfilecontent =''
          localfilecontent<< out
        end
      end
    else
      send_command('copy running-config flash://last-config')
      if transport.session.class.name.include? "Telnet"
        send_command('show file flash://last-config') do |out|
          localfilecontent<< out
        end
      else
        send_command('show file flash://last-config') do |out|
          localfilecontent =''
          localfilecontent<< out
        end
      end
    end
    if localfilecontent =~/Error:\s*(.*)/
      Puppet.info "No current configuration exists "
      configexists=false
    else
      #Remove the following information(sections) from content and so calculate MD5
      #command string(show file flash://last-config)
      #version
      #Last configuration change date
      #startup config last updated date

      for i in 0..3
        localfilecontent.slice!(0..localfilecontent.index('!'))
      end

      digestlocalfile = Digest::MD5.hexdigest(localfilecontent)
    end

    #Copy TFTP file to local
    tftpcopytxt=''
    send_command('copy ' +url+' flash://temp-config') do |out|
      tftpcopytxt<< out
    end
    parseforerror(tftpcopytxt,'copy the TFTP file')

    #Calculate MD5 for TFTP config file
    tftpfilecontent=''
    if transport.session.class.name.include? "Telnet"
      send_command('show file flash://temp-config') do |out|
        tftpfilecontent<< out
      end
    else
      send_command('show file flash://temp-config') do |out|
        tftpfilecontent=''
        tftpfilecontent<< out
      end
    end
    parseforerror(tftpfilecontent,'retrieve the locally stored TFTP config file')

    #Remove the following information(sections) from content and so calculate MD5
    #command string(show file flash://last-config)
    #version
    #Last configuration change date
    #startup config last updated date

    for i in 0..3
      tftpfilecontent.slice!(0..tftpfilecontent.index('!'))
    end

    digesttftpfile = Digest::MD5.hexdigest(tftpfilecontent)

    Puppet.debug "MD5 for Local:"+digesttftpfile
    Puppet.debug "MD5 for Tftp:"+digestlocalfile

    #Compare MD5 and so apply config if required
    if digesttftpfile==digestlocalfile && force == :false
      Puppet.info "No Configuration change"
    else
      #TODO:Sending notification to all opened terminals
      Puppet.info "Configuration changed, applying configuration now!!!"
      sendnotification("Applying configuration now!!!")

      #Taking Backup of existing configuration
      #Delete existing backup file
      send_command('delete flash://'+config+'-backup  no-confirm')
      send_command('copy '+config+' flash://'+config+'-backup')

      #In case startup-config already exists it will prompt for overwrite confirmation
      if config=='startup-config'
        if configexists
          send_command('copy flash://temp-config '+config, :prompt => /.\n/)
          send_command("yes")
        else
          send_command('copy flash://temp-config '+config) do |out|
            txt<< out
          end
        end
        startupconfigchanged=true
      else
        send_command('copy flash://temp-config '+config) do |out|
          txt<< out
        end
        parseforerror(txt,"apply the running configuration")
      end
    end

  rescue Exception => e
    Puppet.err e.message
    Puppet.err e.backtrace.inspect

    #ensure: Always delete the temporary files
  ensure
    send_command('delete flash://last-config no-confirm')
    send_command('delete flash://temp-config no-confirm')

    if startupconfigchanged
      #TODO:Sending notification to all opened terminals
      Puppet.info("Rebooting the switch Now!!!")
      sendnotification("Rebooting the switch Now!!!")

      #Reboot the switch
      tryrebootswitch()

    end
    return txt
  end

  def copy_files
    Puppet.debug("Copying files to TFTP share")
    tftp_share = @copy_to_tftp[0]
    tftp_path = @copy_to_tftp[1]
    firmware_name = tftp_path.split('/')[-1]
    full_tftp_path = tftp_share + "/" + tftp_path
    tftp_dir = full_tftp_path.split('/')[0..-2].join('/')
    if !File.exist? tftp_dir
      FileUtils.mkdir_p tftp_dir
    end
    FileUtils.cp @source_file_path, full_tftp_path
    FileUtils.chmod_R 0777, tftp_dir
    return tftp_path
  end

  def parseforerror(outtxt,placestr)
    if outtxt =~/Error:\s*(.*)/
      raise "Unable to "+placestr+".Reason:#{$1}"
    end
  end

  def tryrebootswitch()
    #Some times sending reload command returning with console prompt without doing anything; in that case retry reload, for max 3 times
    for i in 0..2
      if rebootswitch()
        break
      end
    end
  end

  def rebootswitch
    flagfirstresponse=false
    flagsecondresponse=false
    flagthirdresponse=false

    send_command("reload")  do |out|
      firstresponse =out.scan("System configuration has been modified")
      secondresponse = out.scan("Proceed with reload")
      unless firstresponse.empty?
        flagfirstresponse=true
        break
      end
      unless secondresponse.empty?
        flagsecondresponse=true
        break
      end
    end

    #Some times sending reload command returning with console prompt without doing anything, in that case retry reload
    if !flagfirstresponse && !flagsecondresponse
      return false
    end

    if flagfirstresponse
      send_command("no") do |out|
        thirdresponse = out.scan("Proceed with reload")
        unless thirdresponse.empty?
          flagthirdresponse=true
          break
        end
      end
      if flagthirdresponse
        send_command("yes") do |out|
          #without this block expecting for prompt and so hanging
          break
        end
      else
        Puppet.debug "ELSE BLOCK1.2"
      end
    else
      Puppet.debug "ELSE BLOCK1.1"
    end
    if flagsecondresponse
      send_command("yes") do |out|
        #without this block expecting for prompt and so hanging
        break
      end
    else
      Puppet.debug "ELSE BLOCK2"
    end

    #Sleep for 2 mins to wait for switch to come up
    Puppet.info("Going to sleep for 2 minutes, for switch reboot...")
    sleep 120

    Puppet.info("Checking if switch is up, pinging now...")
    for i in 0..20
      if pingable?(transport.session.host)
        Puppet.info("Ping Succeeded, trying to reconnect to switch...")
        break
      else
        Puppet.info("Switch is not up, will retry after 1 min...")
        sleep 60
      end
    end

    #Re-esatblish transport session
    transport.connect_session
    transport.switch.transport=transport.session
    Puppet.info("Session established...")
    return true
  end

  def pingable?(addr)
    output = `ping -c 4 #{addr}`
    !output.include? "100% packet loss"
  end

  def sendnotification(msg)
    send_command("send *",:prompt => /Enter message./)
    if transport.session.class.name.include? "Telnet"
      send_command(msg+"\x1A",:prompt => /Send message./)
    else
      transport.session.sendwithoutnewline(msg+"\x1A")
    end
    send_command("\r")
  end
end