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
     newfirmwareversion = firmwarelocation.split("\/").last.split("-").last.split(".bin").first
     Puppet.debug("  newfirmwareversion  is: " + newfirmwareversion )
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
		raise txt
    end
    Puppet.debug("firmware update done for image B:") 
    rebootSwitch()
    txt = "firmware update is successful"
    return txt
  end
  
  def rebootSwitch()
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
