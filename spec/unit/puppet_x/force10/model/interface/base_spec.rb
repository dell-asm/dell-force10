require "spec_helper"
require "puppet_x/force10/model/interface/base"

describe PuppetX::Force10::Model::Interface::Base do
  let(:base) { PuppetX::Force10::Model::Interface::Base }
  let(:transport) { stub("rspec-transport") }

  describe "#vlans_from_list" do
    it "should return a single vlan as a list" do
      expect(base.vlans_from_list("20")).to eq(["20"])
    end

    it "should return empty string as an empty list" do
      expect(base.vlans_from_list("")).to eq([])
    end

    it "should split comma-separated vlans" do
      expect(base.vlans_from_list("20,21,22")).to eq(%w(20 21 22))
    end

    it "should handle ranges" do
      expect(base.vlans_from_list("18,20-22,28")).to eq(%w(18 20 21 22 28))
    end
  end

  describe "#show_interface_vlans" do
    it "should parse only untagged vlan" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/only_untagged.out")
      transport.stub(:command).with("show interfaces switchport Tengigabitethernet 0/4").and_return(out)
      expect(base.show_interface_vlans(transport, "Tengigabitethernet", "0/4")).to eq(["25", []])
    end

    it "should parse untagged and tagged vlan" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/tagged_and_untagged.out")
      transport.stub(:command).with("show interfaces switchport Tengigabitethernet 0/4").and_return(out)
      expect(base.show_interface_vlans(transport, "Tengigabitethernet", "0/4")).to eq(["18", %w(16 20 23 28)])
    end

    it "should parse untagged and tagged vlan ranges" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/tagged_with_ranges.out")
      transport = Object.new
      transport.stub(:command).with("show interfaces switchport Tengigabitethernet 0/4").and_return(out)
      expect(base.show_interface_vlans(transport, "Tengigabitethernet", "0/4")).to eq(["25", %w(18 19 20 21 28)])
    end
  end

  describe "#update_vlans" do
    let(:interface_type) { "Tengigabit" }
    let(:interface_id) { "0/4" }
    let(:interface_info) { [interface_type, interface_id] }

    it "should add tagged vlans" do
      expect(base).to receive(:show_interface_vlans)
          .with(transport, interface_type, interface_id)
          .and_return(["1", []])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface vlan 28").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["20", "28"], true, interface_info)
    end

    it "should add tagged vlans and unset extra tagged" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["1", ["18"]])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("no tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface vlan 28").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["20", "28"], true, interface_info)
    end

    it "should add tagged vlans and unset any that are untagged" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["20", []])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("no untagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface vlan 28").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["20", "28"], true, interface_info)
    end

    it "should set untagged vlan" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["1", []])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 1").ordered
      expect(transport).to receive(:command).with("no untagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("untagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["18"], false, interface_info)
    end

    it "should set untagged vlan and remove from tagged if needed" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["1", ["18"]])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("no tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 1").ordered
      expect(transport).to receive(:command).with("no untagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 18").ordered
      expect(transport).to receive(:command).with("untagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["18"], false, interface_info)
    end
  end
end
