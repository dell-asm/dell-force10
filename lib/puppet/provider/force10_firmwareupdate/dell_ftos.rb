require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'
require 'fileutils'

Puppet::Type.type(:force10_firmwareupdate).provide :dell_ftos, :parent => Puppet::Provider do
  desc "Dell Force10 switch provider for firmware updates."
  mk_resource_methods

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
    dev = Puppet::Util::NetworkDevice.current
    dev.transport.command('enable')
    reload_type = dev.transport.command('show reload-type').scan(/Next boot\s*:\s*(\S+)/).flatten.first
    Puppet.debug("Reload Type: #{reload_type}")
    if !reload_type.match(/normal-reload/)
      Puppet.debug("Reload type is not 'normal-reload', updated the reload-type of the switch")
      dev.transport.command('conf')
      dev.transport.command('reload-type normal-reload')
      dev.transport.command('end')
      dev.transport.command('write memory')
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
    currentfirmwareversion = dev.switch.facts['dell_force10_application_software_version']
    systemimage = dev.switch.facts['system_image']
    unless currentfirmwareversion and systemimage
      out = dev.transport.command("show version")
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
    deleteflashfile flashfilename
    Puppet.debug("Starting to copy the file to flash drive of switch")
    copysuccessful = false;
    dev.transport.command("copy #{url} flash://#{url.split("\/").last}") do |response|
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
    dev.transport.command("upgrade system #{url} #{nonbootimage}:")  do |out|
      txt << out
    end
    item = txt.scan("successfully")
    if item.empty?
      txt="Firmware update is not successful"
      Puppet.debug(txt)
      deleteflashfile flashfilename
      raise txt
    end
    Puppet.debug("firmware update done for image #{nonbootimage}:")
    change_boot_image(nonbootimage)
    updatestartupconfig()
    tryrebootswitch()
    txt ="firmware update is successfull"
    return txt
  end

  def change_boot_image(nonbootimage)
    dev = Puppet::Util::NetworkDevice.current
    dev.transport.command("config")
    dev.transport.command("boot system stack-unit all primary system #{nonbootimage}:")
    dev.transport.command("exit")
  end
  

  def updatestartupconfig()
    flagfirstresponse=false
    dev = Puppet::Util::NetworkDevice.current
    dev.transport.command("copy running-config startup-config")  do |updateout|
      firstresponse =updateout.scan("Proceed to copy the file")
      unless firstresponse.empty?
        flagfirstresponse=true
        break
      end
    end
    if flagfirstresponse
      txt= ''
      dev.transport.command("yes") do |out|
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
    dev = Puppet::Util::NetworkDevice.current
    flagfirstresponse=false
    flagsecondresponse=false
    flagthirdresponse=false

    dev.transport.command("reload")  do |out|
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
      dev.transport.command("yes") do |out|
        thirdresponse = out.scan("Proceed with reload")
        unless thirdresponse.empty?
          flagthirdresponse=true
          break
        end
      end
      if flagthirdresponse
        dev.transport.command("yes") do |out|
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
      dev.transport.command("yes") do |out|
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
      if pingable?(dev.transport.host)
        Puppet.info("Ping Succeeded, trying to reconnect to switch...")
        break
      else
        Puppet.info("Switch is not up, will retry after 1 min...")
        sleep 60
      end
    end

    #Re-esatblish transport session
    dev.connect_transport
    dev.switch.transport=dev.transport
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
  dev = Puppet::Util::NetworkDevice.current
  url = filename
  firmwareversiondata = ""
  dev.transport.command("show os-version #{url}") do |firmwareresponse|
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
    deleteflashfile flashfilename
    raise err
  end
  return newfirmwareversion
end

def deleteflashfile(filename)
  Puppet.debug("Strating to delete the backed up image")
  dev = Puppet::Util::NetworkDevice.current
  flagfirstresponse=false
  dev.transport.command("delete #{filename}")  do |out|
    firstresponse =out.scan("Proceed to delete")
    Puppet.debug(out)
    unless firstresponse.empty?
      flagfirstresponse=true
      break
    end

  end
  if flagfirstresponse
    txt= ''
    dev.transport.command("yes") do |out|
      txt << out
    end
    Puppet.info(txt)
  else
    return
  end
end
