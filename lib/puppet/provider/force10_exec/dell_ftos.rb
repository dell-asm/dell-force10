require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_exec).provide :dell_ftos, :parent => Puppet::Provider do
  desc "Dell Force10 switch provider for switch commands execution."
  mk_resource_methods
  def run(command, context)
    dev = Puppet::Util::NetworkDevice.current
    txt = ''
    if context == :conf
      dev.transport.command('conf')
      dev.transport.command(command) do |out|
        txt << out
      end
      dev.transport.command('end')
    else
      dev.transport.command(command) do |out|
        txt << out
      end
    end
    return txt
  end
end
