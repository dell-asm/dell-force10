require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_firmwareupdate).provide :dell_ftos, :parent => Puppet::Provider do
  mk_resource_methods
  def run(url, force)
    Puppet.debug("Puppet::Force10_firmwareUpdate*********************")
    Puppet.debug("firmware Image path is: #{url} and force update flag is: #{force}")
    dev = Puppet::Util::NetworkDevice.current
    #    tryrebootswitch()
    currentfirmwareversion = dev.switch.facts['dell_force10_application_software_version']
    Puppet.debug(" currentfirmwareversion: #{currentfirmwareversion}")
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
    dev.transport.command("upgrade system #{url} A:")  do |out|
      txt << out
    end
    item = txt.scan("successfully")
    if item.empty?
      txt="Firmware update is not successful"
      Puppet.debug(txt)
      deleteflashfile flashfilename
      raise txt
    end
    Puppet.debug("firmware update done for image A:")
    dev.transport.command("upgrade system #{url} B:")  do |out|
      txt << out
    end
    item = txt.scan("successfully")
    if item.empty?
      txt = "Firmware update is not successful"
      Puppet.debug(txt)
      deleteflashfile flashfilename
      raise txt
    end
    Puppet.debug("firmware update done for image B:")
    deleteflashfile flashfilename
    tryrebootswitch()
    updatestartupconfig()
    txt = "firmware update is successful"
    return txt
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
