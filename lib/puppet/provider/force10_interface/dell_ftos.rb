require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_interface).provide :dell_ftos, :parent => Puppet::Provider::Dell_ftos do
  desc "Dell Force10 switch provider for interface configuration."
  mk_resource_methods

  def self.get_current(name)
    if !name.nil?
      name=name.gsub(/te |tengigabitethernet /i, "TenGigabitEthernet ")

      name=name.gsub(/fo |fortygige /i, "fortyGigE ")
    end
    transport.switch.interface(name).params_to_hash
  end

  def flush
    transport.switch.interface(name).update(former_properties, properties)
    super
  end

  def exists?
    vlan_info = get_vlan_info
    @iface = name.dup
    # Name translation to map puppet resource name to fact key
    if @iface.include? 'Tengigabitethernet'
      @iface.slice! 'Tengigabitethernet'
      type = 'tengigabit'
    elsif @iface.include? 'Fortygige'
      @iface.slice! 'Fortygige'
      type = 'fortygigabit'
    else
      raise Puppet::Error, "Unknown interface type #{@iface}"
    end
    @ifaces_to_destroy = check_for_interface(vlan_info, @iface, type)
    @ifaces_to_destroy.any?
  end

  def destroy
    interfaces_to_destroy = get_interfaces_to_destroy
    iface = get_iface
    Puppet.debug("Interfaces to destroy: #{interfaces_to_destroy}")
    # translate fact key to switch command
    iface_map = {
        'tengigabit' => 'tengigabitethernet',
        'fortygigabit' => 'fortyGigE',
        'gigabit' => 'gigabitethernet'
    }
    transport.session.command('configure', :prompt => /\(conf\)#\s?\z/n)
    interfaces_to_destroy.each do |vlan, interfaces|
      transport.session.command("interface vlan #{vlan}", :prompt => /\(conf-if-vl-#{vlan}\)#\s?\z/n)
      interfaces.each do |interface|
        type = interface.split('_')[0]
        speed = iface_map[interface.split('_')[1]]
        command_str = "no #{type} #{speed} #{iface}"
        transport.session.command(command_str)
      end
      transport.session.command('exit')
    end
    transport.session.command('exit')
  end

  def get_interfaces_to_destroy
    @ifaces_to_destroy
  end

  def get_iface
    @iface
  end

  def create
    #Does nothing right now
  end

  def get_vlan_info
    JSON.parse(transport.switch.all_vlans)
  end

  def check_for_interface(vlan_info, iface, type)
    port = iface.split('/')[1]
    remove = {}
    vlan_info.each do |vlan_id, info|
      remove_type = []
      ["tagged_#{type}","untagged_#{type}"].each do |k|
        if info[k].is_a? String
          info[k].split(',').each do |e|
            if e.include? '/' and e.include? '-'
              range = e.split('/')[1]
              remove_type << k if port.between?(range.split('-')[0], range.split('-')[1])
            elsif e.include? '/'
              remove_type << k if e.split('/')[1] == port
            elsif e.include? '-'
              remove_type << k if port.between?(e.split('-')[0], e.split('-')[1])
            else
              remove_type << k if e == port
            end
          end
        end
      end
      remove[vlan_id] = remove_type unless remove_type.empty?
    end
    remove
  end

end
