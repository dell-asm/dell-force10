#! /usr/bin/env ruby
require 'spec_provider_helper'
require 'puppet/provider/force10_vlan/dell_ftos'

provider_class = Puppet::Type.type(:force10_vlan).provider(:dell_ftos)

describe provider_class do

  before do
    @vlan = stub_everything 'vlan'
    @vlan.stubs(:name).returns('172')
    @vlan.stubs(:params_to_hash)
    @vlans = [ @vlan ]

    @switch = stub_everything 'switch'
    @switch.stubs(:vlan).returns(@vlans)
    @switch.stubs(:params_to_hash).returns({})

    @device = stub_everything 'device'
    @device.stubs(:switch).returns(@switch)

    @resource = stub('resource', :desc => "INT")

    @provider = provider_class.new(@device, @resource)

  end

  it "should have a parent of Puppet::Provider::Dell_ftos" do
    provider_class.should < Puppet::Provider::Dell_ftos
  end

  it "should have an instances method" do
    provider_class.should respond_to(:instances)
  end

  describe "when looking up instances at prefetch" do
    before do
      @device.stubs(:command).yields(@device)
    end

    it "should delegate to the device vlan fetcher" do
      @device.expects(:switch).returns(@switch)
      @switch.expects(:vlan).with('172').returns(@vlan)
      @vlan.expects(:params_to_hash)
      provider_class.lookup(@device, '172')
    end

    it "should return the given configuration data" do
      @device.expects(:switch).returns(@switch)
      @switch.expects(:vlan).with('172').returns(@vlan)
      @vlan.expects(:params_to_hash).returns({ :desc => "INT" })
      provider_class.lookup(@device, '172').should == { :desc => "INT" }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the device configuration update method with current and past properties" do
      @instance = provider_class.new(@device, :ensure => :present, :name => '172', :mtu => '1110')
      @instance.resource = @resource
      @resource.stubs(:[]).with(:name).returns('172')
      @instance.stubs(:device).returns(@device)
      @switch.expects(:vlan).with('172').returns(@vlan)
      @switch.stubs(:facts).returns({})
      @vlan.expects(:update).with({:ensure => :present, :name => '172', :mtu => '1110'},
      {:ensure => :present, :name => '172', :mtu => '1110'})
      @vlan.expects(:update).never

      #@instance.desc = "FOOBAR"
      @instance.flush
    end
  end

end

