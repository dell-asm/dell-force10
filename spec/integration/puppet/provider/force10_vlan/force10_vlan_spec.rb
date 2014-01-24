#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/dell_ftos/device'
require 'puppet/provider/force10_vlan/dell_ftos'
require 'pp'
require 'spec_lib/puppet_spec/deviceconf'

include PuppetSpec::Deviceconf

describe "Integration test for force 10 vlan" do

  device_conf =  YAML.load_file(my_deviceurl('force10','device_conf.yml'))
  provider_class = Puppet::Type.type(:force10_vlan).provider(:dell_ftos)

  let :force10_vlan do
    Puppet::Type.type(:force10_vlan).new(
    :name  => '180',
    :desc      => 'test desc',
    :vlan_name => 'test name',
    :ensure    => 'present'
    )
  end

  before do
    @device = provider_class.device(device_conf['url'])
  end

  context 'when configuring vlan' do
    it "should configure vlan" do
      resultexpected={:desc => force10_vlan[:desc], :vlan_name => force10_vlan[:vlan_name]}
      preresult = provider_class.lookup(@device, force10_vlan[:name])
      @device.switch.vlan(force10_vlan[:name]).update(preresult,{:desc => force10_vlan[:desc], :vlan_name => force10_vlan[:vlan_name]})
      postresult = provider_class.lookup(@device, force10_vlan[:name])
      postresult.should include(resultexpected)
    end
  end

end

