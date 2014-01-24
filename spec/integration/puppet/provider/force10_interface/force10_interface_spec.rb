#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/dell_ftos/device'
require 'puppet/provider/force10_interface/dell_ftos'
require 'pp'
require 'spec_lib/puppet_spec/deviceconf'

include PuppetSpec::Deviceconf
describe "Integration test for force 10 interface" do

  device_conf =  YAML.load_file(my_deviceurl('force10','device_conf.yml'))
  provider_class = Puppet::Type.type(:force10_interface).provider(:dell_ftos)

  let :force10_interface do
    Puppet::Type.type(:force10_interface).new(
    :name  => 'te 0/6',
    :mtu => '600',
    :shutdown => 'true'
    )
  end
  before do
    @device = provider_class.device(device_conf['url'])
  end

  context 'when configuring interface' do
    it "should configure interface" do
      resultexpected={:mtu => force10_interface[:mtu], :shutdown => force10_interface[:shutdown]}
      preresult = provider_class.lookup(@device, force10_interface[:name])
      @device.switch.interface(force10_interface[:name]).update(preresult,{:mtu => force10_interface[:mtu], :shutdown => force10_interface[:shutdown]})
      postresult = provider_class.lookup(@device, force10_interface[:name])
      postresult.should include(resultexpected)
    end
  end

end

