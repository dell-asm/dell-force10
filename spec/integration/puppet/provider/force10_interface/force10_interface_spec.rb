#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/dell_ftos/device'
require 'puppet/provider/force10_interface/dell_ftos'
require 'pp'

describe "Integration test for force 10 interface" do

  provider_class = Puppet::Type.type(:force10_interface).provider(:dell_ftos)

  before do

    @device = provider_class.device("telnet://admin:Dell_123$@172.152.0.24/?enable=Dell_123$")
  end

  let :force10_interface do
    Puppet::Type.type(:force10_interface).new(
    :name  => 'te 0/6',
    :mtu => '600',
    :shutdown => 'true'
    )
  end

  context 'when configuring interface' do
    it "should configure interface" do
      preresult = provider_class.lookup(@device, force10_interface[:name])
      @device.switch.interface(force10_interface[:name]).update(preresult,{:mtu => force10_interface[:mtu], :shutdown => force10_interface[:shutdown]})
      postresult = provider_class.lookup(@device, force10_interface[:name])
      postresult.should include({:mtu => force10_interface[:mtu], :shutdown => force10_interface[:shutdown]})
    end
  end

end

