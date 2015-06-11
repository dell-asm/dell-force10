#Quad Mode configuration

require 'puppet_x/force10/model'
require 'puppet_x/force10/model/quadmode'

module PuppetX::Force10::Model::Quadmode::Base

  def self.ifprop(base, param, base_command = param, &block)
    Puppet.debug("Base: #{base.name}, param: #{param}, base_command: #{base_command}")
    interface_num = base.name.scan(/(\d+)/).flatten.last.to_i
    base.register_scoped param, /(stack-unit 0 port\s+(\d+)\s+portmode quad)/ do
      cmd 'show running-config | grep quad'
      match /\d+/
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
        Puppet.debug("Value of txt: #{txt}")
        unless txt.nil?
          txt.match(/stack.*/) ? :present : :absent
        else
          :absent
        end
      end
      default :absent
      add { |*_| }
      remove { |*_| }
    end

  end

end
