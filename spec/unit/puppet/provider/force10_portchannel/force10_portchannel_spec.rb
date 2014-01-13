#! /usr/bin/env ruby
require 'spec_provider_helper'
require 'puppet/provider/force10_portchannel/dell_ftos'

provider_class = Puppet::Type.type(:force10_portchannel).provider(:dell_ftos)

describe provider_class do

  before do
    @portchannel = stub_everything 'portchannel'
    @portchannel.stubs(:name).returns('152')
    @portchannel.stubs(:params_to_hash)
    @portchannels = [ @portchannel ]

    @switch = stub_everything 'switch'
    @switch.stubs(:portchannel).returns(@portchannels)
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

    it "should delegate to the device portchannel fetcher" do
      @device.expects(:switch).returns(@switch)
      @switch.expects(:portchannel).with('152').returns(@portchannel)
      @portchannel.expects(:params_to_hash)
      provider_class.lookup(@device, '152')
    end

    it "should return the given configuration data" do
      @device.expects(:switch).returns(@switch)
      @switch.expects(:portchannel).with('152').returns(@portchannel)
      @portchannel.expects(:params_to_hash).returns({ :desc => "INT" })
      provider_class.lookup(@device, '152').should == { :desc => "INT" }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the device configuration update method with current and past properties" do
      @instance = provider_class.new(@device, :ensure => :present, :name => '152', :mtu => '1110')
      @instance.resource = @resource
      @resource.stubs(:[]).with(:name).returns('152')
      @instance.stubs(:device).returns(@device)
      @switch.expects(:portchannel).with('152').returns(@portchannel)
      @switch.stubs(:facts).returns({})
      @portchannel.expects(:update).with({:ensure => :present, :name => '152', :mtu => '1110'},
      {:ensure => :present, :name => '152', :mtu => '1110'})
      @portchannel.expects(:update).never

      #@instance.desc = "FOOBAR"
      @instance.flush
    end
  end

end
