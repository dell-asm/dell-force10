#The class has the methods for parsing and keeping parameters of resource type(Like vlan, portchannel etc) values
require 'puppet_x/force10/model'
require 'puppet_x/force10/model/generic_value'
require 'puppet/util/monkey_patches_ftos'

class PuppetX::Force10::Model::ScopedValue < PuppetX::Force10::Model::GenericValue
  attr_accessor :scope, :scope_name
  def scope(*args, &block)
    return @scope if args.empty? && block.nil?
    @scope = (block.nil? ? args.first : block)
  end

  def scope_name(*args, &block)
    return @scope_name if args.empty? && block.nil?
    @scope_name = (block.nil? ? args.first : block)
  end

  # pass a block if a single scope can match multiple names
  # the block must split up the given content and matched name
  # and return a list of new content and name pairs
  def scope_match(&block)
    return @scope_match if block.nil?
    @scope_match = block
  end

  def munge_scope(content, name)
    if self.scope_match.is_a? Proc
      self.scope_match.call(content, name)
    else
      [[content, name]]
    end
  end

  def extract_scope(txt)
    raise "No scope_name configured" if @scope_name.nil?
    return if txt.nil? || txt.empty?
    munged = txt.scan(scope).collect do |content,name|
      munge_scope(content,name)
    end.reduce(:+) || []

    munged.collect do |pair|
      (content,name) = pair
      # We want to compare the strings without spaces and caps
      # Example:  Interface could be something like "TenGigabitEthernet 0/23" with spaces or "tengigabitethernet0/23", and both are valid for command line
      content if (name.to_s || '').gsub(/\s+/, "").casecmp(@scope_name.to_s.gsub(/\s+/, "")) == 0
    end.reject { |val| val.nil? }.first
  end

  def parse(txt)
    result = extract_scope(txt)
    if result.nil? || result.empty?
      Puppet.debug("Scope #{scope} not found for Param #{name}")
      return
    end
    if self.match.is_a?(Proc)
      self.value = self.match.call(result)
    else
      self.value = result.scan(self.match).flatten[self.idx]
    end
    self.evaluated = true
  end

  def parseforerror(outtxt,placestr)
    match = outtxt.match(/Error:\s*(?<error>.*)/)

    if match
      return if match[:error] =~ /Name already exists/

      Puppet.info("ERROR:%s" % match[:error])
      raise("Unable to %s.Reason:%s" % [placestr, match[:error]])
    end
  end

  #untagged interfaces can only belong to one VLAN at a time - and so checking for mappings and so doing no untag
  def nountagintffromoothervlans(interfacename, interfacevalue, vlanname)
    transport.command("exit")
    transport.command("exit")

    interfaces = parse_interface_value(interfacevalue)

    interfaces.each do |interface|
      outtxt=""
      transport.command("show interfaces switchport #{interfacename} #{interface}") do |out|
        outtxt<< out
      end
      chkvlan=outtxt.match(/.*Vlans\s+(U)\s+(.*$)/)
      if chkvlan.nil?
        Puppet.debug "interface #{interfacename} #{interface} not UNTAGGED to any other VLAN "
      else
        transport.command("conf")
        #Except Default VLAN
        unless $2=="1"
          transport.command("interface vlan #{$2}")
          transport.command("no untagged #{interfacename} #{interface}")
          transport.command("exit")
          transport.command("exit")
        end
      end
      transport.command("conf")
      transport.command("interface vlan #{vlanname}")
    end
  end

  # Takes a string of interfaces and returns list
  #
  # @note ["0/1","0/3","0/5"] = parse_interface_value("0/1,3,5")
  # @note ["0/1", "1/2"] = parse_interface_value("0/1,1/2")
  # @interfacevalue [String] interface value from param. ex: "0/1,3,5"
  # @return [Array<String>] returns list of interfaces
  def parse_interface_value(interfacevalue)
    curr_stack = 0
    interfacevalue.split(",").map do |stack_and_port|
      pieces = stack_and_port.split("/").map(&:strip)
      case pieces.size
        when 1
          stack = curr_stack
          port = pieces[0]
        when 2
          stack = curr_stack = pieces[0]
          port = pieces[1]
        else
          raise(ArgumentError, "Invalid port %s (%s)" % [stack_and_port, interfacevalue])
      end
      begin
        "%d/%d" % [stack, port]
      rescue ArgumentError => e
        raise(ArgumentError, "Non-numeric port or stack %s (%s)" % [stack_and_port, interfacevalue])
      end
    end
  end
end
