require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'
require 'fileutils'

Puppet::Type.type(:force10_firmwareupdate).provide :dell_ftos, :parent => Puppet::Provider do
  desc "Dell Force10 switch provider for firmware updates."
  mk_resource_methods

  def transport
    @transport ||= PuppetX::Force10::Transport.new(Puppet[:certname])
  end

  def send_command(cmd)
    transport.session.command(cmd) do |line|
      yield line if block_given?
    end
  end

  def move_to_tftp(copy_to_tftp, path)
    Puppet.debug("Copying files to TFTP share")
    tftp_share = copy_to_tftp[0]
    tftp_path = copy_to_tftp[1]
    full_tftp_path = tftp_share + "/" + tftp_path
    tftp_dir = full_tftp_path.split('/')[0..-2].join('/')
    if !File.exist? tftp_dir
      FileUtils.mkdir_p tftp_dir
    end
    FileUtils.cp path, full_tftp_path
    FileUtils.chmod_R 0755, tftp_dir
  end

  def disable_bmp_mode
    # Need to skip disable BMP mode configuration for IO Aggregators and FNIOA
    switch_model = ( transport.switch.facts['product_name'] || '' )
    return true if switch_model.match(/IOA|Aggregator/i)

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

  def run(url, force, copy_to_tftp=nil, path=nil)
    Puppet.debug("Puppet::Force10_firmwareUpdate*********************")
    disable_bmp_mode
    if copy_to_tftp 
      move_to_tftp(copy_to_tftp,path)
    end
    Puppet.debug("firmware Image path is: #{url} and force update flag is: #{force}")
    dev = Puppet::Util::NetworkDevice.current
    #    tryrebootswitch()
    currentfirmwareversion = transport.switch.facts['dell_force10_application_software_version']
    systemimage = transport.switch.facts['system_image']
    unless currentfirmwareversion and systemimage
      out = send_command("show version")
      versionmatch = out.match(/^Dell\s+Force10\s+Application\s+Software\s+Version:\s+(\S+)$|Dell Application Software Version:\s+(.*?)$/m)
      currentfirmwareversion = versionmatch[2]
      imagematch = out.match(/^System image file is\s*"(.*)"/)
      systemimage = imagematch[1][-1]
    end
    # Set the non boot image to oposite of system (we will only flash nonboot)
    nonbootimage = systemimage[-1] == 'A' ? 'B' : 'A'
    Puppet.debug(" currentfirmwareversion: #{currentfirmwareversion}")
    Puppet.debug(" systembootimage: #{systemimage}")
    #newfirmwareversion = url.split("\/").last.split("-").last.split(".bin").first
    copyresponse = ""
    flashfilename= "flash://#{url.split("\/").last}"
    deleteflashfiles
    Puppet.debug("Starting to copy the file to flash drive of switch")
    copysuccessful = false;
    send_command("copy #{url} flash://#{url.split("\/").last}") do |response|
      firstresponse = response.scan("successfully copied")
      unless firstresponse.empty?
        copysuccessful=true
        break
      end
    end
    unless copysuccessful
      err = "Unable to copy the file to the switch. Copy failed"
      Puppet.debug(err)
      raise err
    end
    newfirmwareversion = trygetfirmwareversion flashfilename
    Puppet.debug("firmwareversion  is: " + newfirmwareversion )
    txt = ''
    if (currentfirmwareversion.eql? newfirmwareversion) && force == :false
      Puppet.debug("Existing Firmware versions is same as new Firmware version, so not doing firmware update")
      txt = "Existing Firmware versions is same as new Firmware version, so not doing firmware update"
      return txt
    end
    send_command("upgrade system #{url} #{nonbootimage}:")  do |out|
      txt << out
    end
    item = txt.scan("successfully")
    if item.empty?
      msg = "Firmware update is not successful"
      Puppet.debug(msg)
      Puppet.debug(txt)
      deleteflashfiles
      raise msg
    end
    Puppet.debug("firmware update done for image #{nonbootimage}:")
    change_boot_image(nonbootimage)
    updatestartupconfig()
    tryrebootswitch()
    txt ="firmware update is successfull"
    return txt
  end

  def change_boot_image(nonbootimage)
    send_command("config")
    send_command("boot system stack-unit all primary system #{nonbootimage}:")
    send_command("exit")
  end
  

  def updatestartupconfig()
    flagfirstresponse=false
    send_command("copy running-config startup-config")  do |updateout|
      firstresponse =updateout.scan("Proceed to copy the file")
      unless firstresponse.empty?
        flagfirstresponse=true
        break
      end
    end
    if flagfirstresponse
      txt= ''
      send_command("yes") do |out|
        txt << out
      end
      Puppet.debug(txt)
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

  def rebootswitch()
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
      send_command("yes") do |out|
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

    #Sleep for 5 mins to wait for switch to come up
    Puppet.info("Going to sleep for 5 minutes, for switch reboot...")
    sleep 300

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

    #Re-establish transport session
    transport.connect_session
    transport.switch.transport=transport.session
    Puppet.info("Session established...")
    return true
  end

  def pingable?(addr)
    output = `ping -c 4 #{addr}`
    !output.include? "100% packet loss"
  end
end

def trygetfirmwareversion(filename)
  #Some times sending reload command returning with console prompt without doing anything; in that case retry reload, for max 3 times
  for i in 0..3
    firmwareVersion = getfirmwareversion filename
    unless firmwareVersion.eql? "false"
      break
    end
  end
  return firmwareVersion
end

def getfirmwareversion(filename)
  url = filename
  firmwareversiondata = ""
  send_command("show os-version #{url}") do |firmwareresponse|
    firmwareversiondata << firmwareresponse
  end
  firmwarewversionlineArr = firmwareversiondata.match(/^\s*(.*:\s*\b([A-Za-z]{1}[A-Za-z0-9]*)\b\s*\b([0-9]{1}[0-9\-\.]*)\b.*)/)
  if firmwarewversionlineArr.nil?
    return "false"
  end
  firmwarewversionline = firmwarewversionlineArr[1]
  Puppet.debug("The version of the firmware update file is  #{firmwarewversionline.split("\ ")[2]}")
  newfirmwareversion = firmwarewversionline.split("\ ")[2]
  Puppet.debug("firmwareversion  is: " + newfirmwareversion )

  if firmwareversiondata.to_s == '' or firmwarewversionline.to_s == '' or newfirmwareversion.to_s == ''
    err = "Unable to determine the version of the update file. Firmware update failed"
    Puppet.debug(err)
    deleteflashfiles
    raise err
  end
  return newfirmwareversion
end

def deleteflashfiles
  Puppet.debug("Starting to delete the backed up images")
  send_command("delete flash://*.bin no-confirm")
  Puppet.debug("Binary images removed from flash storage")
end
