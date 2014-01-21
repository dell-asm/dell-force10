#! /usr/bin/env ruby

require 'spec_provider_helper'
require 'puppet/util/network_device/dell_ftos/device'
require 'puppet/provider/force10_portchannel/dell_ftos'

describe "Integration test for IOA Interface" do

  provider_class = Puppet::Type.type(:force10_portchannel).provider(:dell_ftos)

  before do
    #Facter.stub(:value).with(:url).and_return(device_conf['url'])
    @device = provider_class.device("ssh://admin:Dell_123$@172.152.0.23")
  end

  let :config_force10_portchannel do
    Puppet::Type.type(:force10_portchannel).new(
    :name  => '126',
    :desc => 'Port channel test decsription',
    :mtu => '3300',
    :shutdown => true,
    :ensure => :present
    )
  end

  context 'when configuring portchannel' do
    it "should configure force10 portchannel" do
      preresult = provider_class.lookup(@device, config_force10_portchannel[:name])

      @device.switch.portchannel(config_force10_portchannel[:name]).update(preresult,{:ensure => :present, :desc => config_force10_portchannel[:desc], :mtu => config_force10_portchannel[:mtu], :shutdown =>config_force10_portchannel[:shutdown]})

      postresult = provider_class.lookup(@device, config_force10_portchannel[:name])
      postresult.should eq({:ensure => :present, :desc => config_force10_portchannel[:desc], :mtu => config_force10_portchannel[:mtu], :shutdown => config_force10_portchannel[:shutdown]})
    end
  end

end

