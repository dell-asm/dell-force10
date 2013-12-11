require 'puppet/util/network_device/dell_ftos/device'

class Puppet::Util::NetworkDevice::Singelton_ftos
  def self.lookup(url)
    @map ||= {}
    return @map[url] if @map[url]
    @map[url] = Puppet::Util::NetworkDevice::Dell_ftos::Device.new(url).init
    return @map[url]
  end

  def self.clear
    @map.clear
  end
end
