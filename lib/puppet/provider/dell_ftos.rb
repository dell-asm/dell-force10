require 'puppet/util/network_device/singelton_ftos'
require 'puppet/provider/network_device'

# This is the base Class of all prefetched cisco device providers
class Puppet::Provider::Dell_ftos < Puppet::Provider
  def self.device(url)
    Puppet::Util::NetworkDevice::Singelton_ios.lookup(url)
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      device = Puppet::Util::NetworkDevice.current || device(resource[:device_url])
    end
  end
end
