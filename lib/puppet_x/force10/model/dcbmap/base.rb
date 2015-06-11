#DCB MAP model
#Registers all the properties as parameters and so apply required changes

require 'puppet_x/force10/model'
require 'puppet_x/force10/model/dcbmap'

module PuppetX::Force10::Model::Dcbmap::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(dcb-map\s+(\S+).*?)^!/m do
      cmd 'sh run'
      match /^\s*#{base_command}\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        transport.command("no #{base_command} #{old_value}")
      end
      evaluate(&block) if block
    end
  end

  def self.register(base)
    txt = ''
    ifprop(base, :ensure) do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    base.register_scoped :priority_group_info, /^(dcb-map\s+(\S+).*?)^!/m do
      match /^\s*priority-group\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != {}
          value.keys.each do |key|
            bandwidth = value[key]['bandwidth']
            pfc = value[key]['pfc']
            transport.command("priority-group #{key} bandwidth #{bandwidth} pfc #{pfc}")
          end
        end
      end
      remove { |*_| }
    end
    
    base.register_scoped :priority_pgid, /^(fcoe-map\s+(\S+).*?)^!/m do
      match /^\s*priority-pgid\s+(.*?)\s*/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("priority-pgid #{value}")
        end
      end
      remove { |*_| }
    end
    
  end

end
