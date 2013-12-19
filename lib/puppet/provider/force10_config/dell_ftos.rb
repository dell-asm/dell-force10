require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_config).provide :dell_ftos, :parent => Puppet::Provider do
  mk_resource_methods

  def run(url, startup_config)   
    dev = Puppet::Util::NetworkDevice.current
    txt = ''
    if startup_config == :true
       dev.transport.command('copy ' +url+' startup-config') do |out|
        txt << out
      end     
    else
      dev.transport.command('copy ' +url+' running-config') do |out|
        txt << out
      end
    end
    return txt
  end
end