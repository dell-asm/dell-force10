#This is structure class for facts.It provides generic method to parse the fact from command output
require 'puppet_x/force10/value_helper'

class PuppetX::Force10::Fact
  attr_accessor :name, :idx, :value, :evaluated
  extend PuppetX::Force10::ValueHelper
  def initialize(name, transport, facts = nil, idx = 0, &block)
    @name = name
    @idx = idx
    @evaluated = false
    self.instance_eval(&block)
  end

  define_value_method [:cmd, :match, :add, :remove, :before, :after, :match_param, :required]

  def parse(txt)
    if !txt.nil?
      raise(ArgumentError, "Invalid Command:\t #{cmd} while loading facts") if txt =~ /\sError: ((Invalid input)|(Incomplete command))\s/
    end

    if self.match.is_a?(Proc)
      self.value = self.match.call(txt)
    else
      self.value = txt.scan(self.match).flatten[self.idx]
    end
    self.evaluated = true
    raise Puppet::Error, "Fact: #{self.name} is required but didn't evaluate to a proper Value" if self.required == true && (self.value.nil? || self.value.to_s.empty?)
  end

  def uptime_to_seconds(uptime)
    # TODO: Review
    return if uptime.nil?
    captures = (uptime.match /^(?:(\d+) years?,)?\s*(?:(\d+) weeks?,)?\s*(?:(\d+) days?,)?\s*(?:(\d+) hours?,)?\s*(\d+) minutes?$/).captures
    seconds = captures.zip([31536000, 604800, 86400, 3600, 60]).inject(0) do |total, (duration,secondsmultiplier)|
      total + (duration.nil? ? 0 : duration.to_i * secondsmultiplier)
    end
  end

end
