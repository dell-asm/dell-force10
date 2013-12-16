require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'

Puppet::Type.type(:dell_exec).provide :dell_ftos, :parent => Puppet::Provider do
  mk_resource_methods
  def run(command, context)
    Puppet.debug("Puppet::puppet_exec*********************")
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
