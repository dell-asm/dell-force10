require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/generic_value'
require 'puppet/util/monkey_patches_ftos'

class Puppet::Util::NetworkDevice::Dell_ftos::Model::ModelValue < Puppet::Util::NetworkDevice::Dell_ftos::Model::GenericValue

  def model(*args, &block)
    return @model if args.empty? && block.nil?
    @model = (block.nil? ? args.first : block)
  end

  def parse(txt)
    if self.match.is_a?(Proc)
      self.value = self.match.call(txt)
    else
      self.value = txt.scan(self.match).flatten.collect { |name| model.new(@transport, @facts, { :name => name } ) }
    end
    self.value ||= []
    self.evaluated = true
  end

  def update(transport, old_value)
  end
end
