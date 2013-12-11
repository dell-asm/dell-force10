require 'puppet/util/network_device/dell_ftos'
require 'puppet/util/network_device/value_helper'

class Puppet::Util::NetworkDevice::Dell_ftos::Fact
  attr_accessor :name, :idx, :value, :evaluated
  extend Puppet::Util::NetworkDevice::ValueHelper

  def initialize(name, transport, facts = nil, idx = 0, &block)
    @name = name
    @idx = idx
    @evaluated = false
    self.instance_eval(&block)
  end

  define_value_method [:cmd, :match, :add, :remove, :before, :after, :match_param, :required]

  def parse(txt)
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
    seconds = captures.zip([31536000, 604800, 86400, 3600, 60]).inject(0) do |total, (x,y)|
      total + (x.nil? ? 0 : x.to_i * y)
    end
  end

end
