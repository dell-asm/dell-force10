#Lookup class which helps in registering the facts and retrieving the fact values
require 'puppet_x/force10/fact'
require 'puppet_x/force10/possible_facts'
require 'puppet_x/force10/sorter'
require 'puppet_x/force10/dsl'

class PuppetX::Force10::Facts

  include PuppetX::Force10::Dsl

  attr_reader :transport
  def initialize(transport)
    @transport = transport
  end

  def mod_path_base
    return 'puppet_x/force10/possible_facts'
  end

  def mod_const_base
    return PuppetX::Force10::PossibleFacts
  end

  def param_class
    return PuppetX::Force10::Fact
  end

  # TODO
  def facts
    @params
  end

  def facts_to_hash
    params_to_hash
  end
end
