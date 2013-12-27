#Utility class helps in sorting facts in an dependency based order where the facts dependent on another facts gets to bottom of independent ones.
require 'tsort'

class Puppet::Util::NetworkDevice::Sorter

  include TSort
  def initialize(param)
    @param = param
  end

  def tsort_each_node(&block)
    @param.each_value(&block)
  end

  def tsort_each_child(param, &block)
    @param.each_value.select  { |value|
      next unless value.respond_to?(:before) && value.respond_to?(:after)
      next unless param.respond_to?(:after)
      value.before == param.name || value.name == param.after
    }.each(&block)
  end
end
