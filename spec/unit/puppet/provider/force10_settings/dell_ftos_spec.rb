require 'spec_helper'
require 'rspec/expectations'
require 'json'
require 'puppet'
require 'puppet_x/force10/transport'

provider_class = Puppet::Type.type(:force10_settings).provider(:dell_ftos)

describe provider_class do
  let(:resource) { Puppet::Type.type(:force10_settings).new(
                                                          {
                                                              :name => 'dell_iom-172.17.2.178',
                                                              :hostname => "DELL",
                                                              :spanning_tree_mode => "PVST"
                                                          }
  )}

  let(:provider) {resource.provider}

  before do
    transport = double('transport')
    @session = double(transport).as_null_object
    @session.stub(:command)
  end

  describe "#update_protocol" do
    it "shoud update spanning-tree-mode on switch" do
      @session.should_receive(:command).with('configure')
      @session.should_receive(:command).with('no protocol spanning-tree rstp')
      @session.should_receive(:command).with('protocol spanning-tree pvst')
      @session.should_receive(:command).with('no disable')
      @session.should_receive(:command).with('end')
      provider.update_protocol(@session, "PVST", ["rstp"])
    end

    it "should remove spanning-tree-mode on switch when NONE received" do
      @session.should_receive(:command).with('configure')
      @session.should_receive(:command).with('no protocol spanning-tree rstp')
      @session.should_receive(:command).with('end')
      provider.update_protocol(@session, "NONE", ["rstp"])
    end

    it "should add spanning-tree-mode on switch" do
      @session.should_receive(:command).with('configure')
      @session.should_receive(:command).with('protocol spanning-tree pvst')
      @session.should_receive(:command).with('no disable')
      @session.should_receive(:command).with('end')
      provider.update_protocol(@session, "PVST", [""])
    end

    it "should not add spanning-tree-mode when none exist on switch" do
      @session.should_receive(:command).with('configure')
      @session.should_receive(:command).with('end')
      provider.update_protocol(@session, "none", [""])
    end
  end
end
