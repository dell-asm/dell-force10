require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_firmwareupdate).provide :dell_ftos, :parent => Puppet::Provider do
  mk_resource_methods
  def run(firmwarelocation, forceupdate)
    Puppet.debug("Puppet::Force10_firmwareUpdate*********************")
    Puppet.debug("firmware Image path is: #{firmwarelocation} and force update flag is: #{forceupdate}")
    dev = Puppet::Util::NetworkDevice.current
    currentFirmwareVersion = dev.switch.facts['dell_force10_application_software_version']
    Puppet.debug(" currentfirmwareversion: #{currentFirmwareVersion}")
    #newfirmwareversion = firmwarelocation.split("\/").last.split("-").last.split(".bin").first

    copyResponse = ""
    flashfilename= "flash://#{firmwarelocation.split("\/").last}"
    deleteFlashFile flashfilename
    Puppet.debug("Starting to copy the file to flash drive of switch")
    dev.transport.command("copy #{firmwarelocation} flash://#{firmwarelocation.split("\/").last}") do |response|
      copyResponse << response
    end
    firmwarelocation = flashfilename
    unless copyResponse.include? "successfully copied"
      err = "Unable to copy the file to the switch. Copy failed"
      Puppet.debug(err)
      raise err
    end

    firmwareversiondata = ""
    dev.transport.command("show os-version #{firmwarelocation}") do |firmwareResponse|
      firmwareversiondata << firmwareResponse
    end

    firmwarewversionline = firmwareversiondata.match(/^\s*(.*:\s*\b([A-Za-z]{1}[A-Za-z0-9]*)\b\s*\b([0-9]{1}[0-9\-\.]*)\b.*)/)[1]

    Puppet.debug("The version of the firmware update file is  #{firmwarewversionline.split("\ ")[2]}")
    newfirmwareversion = firmwarewversionline.split("\ ")[2]
    Puppet.debug("firmwareversion  is: " + newfirmwareversion )

    if firmwareversiondata.to_s == '' or firmwarewversionline.to_s == '' or newfirmwareversion.to_s == ''
      err = "Unable to determine the version of the update file. Firmware update failed"
      Puppet.debug(err)
      deleteFlashFile flashfilename
      raise err
    end

    txt = ''
    if currentFirmwareVersion.eql? newfirmwareversion && forceupdate == :false
      Puppet.debug("Existing Firmware versions is same as new Firmware version, so not doing firmware update")
      txt = "Existing Firmware versions is same as new Firmware version, so not doing firmware update"
      return txt
    end
    dev.transport.command("upgrade system #{firmwarelocation} A:")  do |out|
      txt << out
    end
    item = txt.scan("successfully")
    if item.empty?
      txt="Firmware update is not successful"
      Puppet.debug(txt)
      deleteFlashFile flashfilename
      raise txt
    end
    Puppet.debug("firmware update done for image A:")
    dev.transport.command("upgrade system #{firmwarelocation} B:")  do |out|
      txt << out
    end
    item = txt.scan("successfully")
    if item.empty?
      txt = "Firmware update is not successful"
      Puppet.debug(txt)
      deleteFlashFile flashfilename
      raise txt
    end
    Puppet.debug("firmware update done for image B:")
    rebootSwitch()
    txt = "firmware update is successful"
    return txt
  end

  def rebootSwitch()
    deleteFlashFile flashfilename
    dev = Puppet::Util::NetworkDevice.current
    dev.transport.command("reload")  do |reloadout|
      firstresponse = reloadout.scan("System configuration has been modified")
      if firstresponse.empty?
        secondresponse = reloadout.scan("Proceed with reload")
        unless secondresponse.empty?
          Puppet.debug(" second response is not empty, going to reboot now")
          dev.transport.command("yes")
        end
      else
        Puppet.debug("first response is not null,checking for second response")
        dev.transport.command("yes") do |secondresponse|
          thirdresponse = secondresponse.scan("Proceed with reload")
          unless thirdresponse.empty?
            Puppet.debug(" third response is not empty, going to reboot now")
            dev.transport.command("yes")
          end
        end
      end
    end
    Puppet.debug("going to sleep for 10 mins")
    sleep 600
  end
end

def deleteFlashFile(filename)
  Puppet.debug("Strating to delete the backed up image")
  dev = Puppet::Util::NetworkDevice.current
  dev.transport.command("delete #{filename}")  do |deleteout|
    if deleteout.include?"Proceed to delete"
      dev.transport.command("yes")
    end
  end
end
