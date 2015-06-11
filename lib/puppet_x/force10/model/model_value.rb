#The class has the methods for parsing and keeping resource type(Like vlan, portchannel etc) values
require 'puppet_x/force10/model/generic_value'
require 'puppet/util/monkey_patches_ftos'

module PuppetX::Force10::Model
  class ModelValue < PuppetX::Force10::Model::GenericValue
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
end
