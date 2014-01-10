#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device/singelton_ftos'
require 'puppet/util/network_device/dell_ftos/device'
describe Puppet::Util::NetworkDevice::Singelton_ftos do
 
  before(:each) do
    @device = Puppet::Util::NetworkDevice::Dell_ftos::Device.new('ssh://127.0.0.1:22/')
    @device.stubs(:init).returns(@device)
  end

  after(:each) do
    Puppet::Util::NetworkDevice::Singelton_ftos.clear
  end

  describe 'when initializing the remote network device singleton' do
    it 'should create a network device instance' do
      Puppet::Util::NetworkDevice::Dell_ftos::Device.expects(:new).returns(@device)
      Puppet::Util::NetworkDevice::Singelton_ftos.lookup('ssh://127.0.0.1:22/').should == @device
    end

    it 'should cache the network device' do
      Puppet::Util::NetworkDevice::Dell_ftos::Device.expects(:new).times(1).returns(@device)
      Puppet::Util::NetworkDevice::Singelton_ftos.lookup('ssh://127.0.0.1:22/').should == @device
      Puppet::Util::NetworkDevice::Singelton_ftos.lookup('ssh://127.0.0.1:22/').should == @device
    end
  end
end
