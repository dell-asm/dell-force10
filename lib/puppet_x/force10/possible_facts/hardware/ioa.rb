require 'puppet_x/force10/possible_facts'
require 'puppet_x/force10/possible_facts/hardware'

module PuppetX::Force10::PossibleFacts::Hardware::Ioa
  CMD_SHOW_RUNNING_INTERFACE ="show running-config interface" unless const_defined?(:CMD_SHOW_RUNNING_INTERFACE)

  def self.register(base)

    base.register_param 'vlan_information' do
      match do |txt|
        PuppetX::Force10::PossibleFacts::Hardware::Ioa.vlan_information(txt).to_json
      end
      cmd CMD_SHOW_RUNNING_INTERFACE
    end

  end

  def self.vlan_data
    {
      "tagged_tengigabit" => [],
      "untagged_tengigabit" => [],
      "tagged_fortygigabit" => [],
      "untagged_fortygigabit" => [],
      "tagged_portchannel" => [],
      "untagged_portchannel" =>[]
    }
  end

  def self.vlan_information(txt)
    #Display information on configured Port Channel groups in JSON Format
    vlan_information = {}
    begin
      interfaces = (txt.scan(/((!\s+interface\s+(TenGigabitEthernet|Port-channel|FortyGigE)\s+\d+.*?shutdown\s+))/m) || [] ).flatten
      interfaces.each do |interface_detail|
        interface_info = interface_detail.scan(/^interface\s+(TenGigabitEthernet|Port-channel|FortyGigE)\s+(\d\/\d*)/).flatten
        interface_location = interface_info.last
        speed = interface_info.first
        i_type = case speed
                   when "TenGigabitEthernet"
                     "tengigabit"
                   when "Port-channel"
                     "portchannel"
                   when "FortyGigE"
                     "fortygigabit"
                 end
        interface_detail.scan(/^\svlan\s+(tagged|untagged)\s+(.*?)$/mi).each do |vlan_line|
          mode = vlan_line[0]
          vlan_group = vlan_line[1]
          vlan_set = vlan_group unless vlan_group.include? ","
          vlan_group.split(",").each do |vlan|
            vlan_set = []
            if vlan.include? "-"
              vlan_start = vlan.split("-")[0].to_i
              vlan_fin = vlan.split("-")[1].to_i
              (vlan_start..vlan_fin).each do |i|
                vlan_set << i.to_s
              end
            else
              vlan_set << vlan
            end
            vlan_set.each do |v|
              vlan_information[v.to_s] ||= self.vlan_data
              vlan_information[v.to_s]["#{mode}_#{i_type}"] << interface_location
            end
          end
        end
        if interface_detail.match(/^\sauto\s+vlan/)
          (1..4095).each do |v|
            vlan_information[v.to_s] ||= self.vlan_data
            vlan_information[v.to_s]["tagged_#{i_type}"] << interface_location
          end
        end
      end
      #Clean up data
      vlan_information.each do |vlan, data|
        data.each do |type, ports|
          next unless ports
          if ports.empty?
            ports = ""
          else
            ports = ports.uniq.join(",") if ports.class == Array
          end
          data[type] = ports
        end
      end
    rescue => e
      Puppet.debug("Failed to get vlan_information fact")
      Puppet.debug("#{e.message}\n#{e.backtrace}")
    end

    vlan_information
  end
end
