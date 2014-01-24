#! /usr/bin/env ruby

require 'spec_provider_helper'
require 'puppet/util/network_device/dell_ftos/device'
require 'puppet/provider/force10_portchannel/dell_ftos'
require 'spec_lib/puppet_spec/deviceconf'

include PuppetSpec::Deviceconf

describe "Integration test for IOA Interface" do
  device_conf =  YAML.load_file(my_deviceurl('force10','device_conf.yml'))
  provider_class = Puppet::Type.type(:force10_portchannel).provider(:dell_ftos)

  let :config_force10_portchannel do
    Puppet::Type.type(:force10_portchannel).new(
    :name  => '126',
    :desc => 'Port channel test decsription',
    :mtu => '3300',
    :shutdown => true,
    :ensure => :present
    )
  end

  before do
    @device = provider_class.device(device_conf['url'])
  end

  context 'when configuring portchannel' do
    it "should configure force10 portchannel" do
      resultexpected={:ensure => :present, :desc => config_force10_portchannel[:desc], :mtu => config_force10_portchannel[:mtu], :shutdown => config_force10_portchannel[:shutdown]}
      preresult = provider_class.lookup(@device, config_force10_portchannel[:name])

      @device.switch.portchannel(config_force10_portchannel[:name]).update(preresult,{:ensure => :present, :desc => config_force10_portchannel[:desc], :mtu => config_force10_portchannel[:mtu], :shutdown =>config_force10_portchannel[:shutdown]})

      postresult = provider_class.lookup(@device, config_force10_portchannel[:name])
      postresult.should include(resultexpected)
    end
  end

end

