require "spec_helper"
require "puppet_x/force10/model/interface/base"

describe PuppetX::Force10::Model::Interface::Base do
  let(:base) { PuppetX::Force10::Model::Interface::Base }
  let(:transport) { stub("rspec-transport") }

  describe "#show_interface_vlans" do
    it "should parse only untagged vlan" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/only_untagged.out")
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      transport.stub(:command).with("show interfaces switchport Te 0/4").and_return(out)
      expect(base.show_interface_vlans(transport, "Te 0/4")).to eq([[25], []])
    end

    it "should parse untagged and tagged vlan" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/tagged_and_untagged.out")
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      transport.stub(:command).with("show interfaces switchport Te 0/4").and_return(out)
      expect(base.show_interface_vlans(transport, "Te 0/4")).to eq([[18], [16, 20, 23, 28]])
    end

    it "should parse untagged and tagged vlan ranges" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/tagged_with_ranges.out")
      transport = Object.new
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      transport.stub(:command).with("show interfaces switchport Te 0/4").and_return(out)
      expect(base.show_interface_vlans(transport, "Te 0/4")).to eq([[25], [18, 19, 20, 21, 28]])
    end
  end

  describe "#update_untagged_vlans" do
    it "should unset untagged vlan" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("no untagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("untagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_untagged_vlans(transport, "20", [18], "Te 0/14")
    end

    it "should add untagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("untagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_untagged_vlans(transport, "20", [1], "Te 0/14")
    end

    it "should unset extra tagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("no untagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_untagged_vlans(transport, "1", [18], "Te 0/14")
    end
  end

  describe "#update_tagged_vlans" do
    it "should unset extra tagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("no tagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("show interfaces switchport Te 0/14").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_tagged_vlans(transport, "20", [18, 20], "Te 0/14")
    end

    it "should add tagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("tagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("show interfaces switchport Te 0/14").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_tagged_vlans(transport, "20", [], "Te 0/14")
    end

    it "should unset extra tagged vlans" do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("no tagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("no tagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 28").ordered
      expect(transport).to receive(:command).with("tagged Te 0/14").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("show interfaces switchport Te 0/14").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_tagged_vlans(transport, "28", [18, 20], "Te 0/14")
    end
  end

  describe "#show_stp_val" do
    let(:interface_type) { "Te 0/14" }
    it "should parse only existing spanning-tree protcol edge-port" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/show_switch_spt.out")
      transport.stub(:command).with("show config").and_return(out)
      expect(base.show_stp_val(transport, "Te 0/14")).to eq(["mstp", "rstp", "pvst"])
    end
    it "should parse no spanning-tree edge-port" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/show_switch_no_spt.out")
      transport.stub(:command).with("show config").and_return(out)
      expect(base.show_stp_val(transport, "Te 0/14")).to eq([])
    end
  end

  describe "#update_stp" do
    it "should add valid spanning-tree protocol type" do
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("spanning-tree mvst edge-port").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("spanning-tree rstp edge-port").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_stp(transport, "Te 0/14", ["pvst"], ["mvst", "rstp", "pvst"])
    end

    it "should add correct spanning-tree protocol type" do
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("no spanning-tree mvst edge-port").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("no spanning-tree rstp edge-port").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("spanning-tree pvst edge-port").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_stp(transport, "Te 0/14", ["mvst", "rstp"], ["pvst"])
    end

    it "should add parsed spanning-tree protocol type" do
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("spanning-tree pvst edge-port").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      base.update_stp(transport, "Te 0/14", [], ["pvst"])
    end
  end
end
