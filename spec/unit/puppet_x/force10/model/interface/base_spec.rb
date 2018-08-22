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

  describe "#update_port_channel" do
    let(:interface_type) { "Tengigabit" }
    let(:interface_id) { "0/4" }
    let(:interface_info) { [interface_type, interface_id] }

    it "should remove interface from port-channel" do
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface port-channel 3").ordered
      expect(transport).to receive(:command).with("no channel-member Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered

      base.update_port_channel(transport, 3, interface_info, true)
    end

    it "should add interface to a port-channel" do
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface port-channel 3").ordered
      expect(transport).to receive(:command).with("channel-member Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered

      base.update_port_channel(transport, 3, interface_info, false)
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

    it "should add tagged vlans and do not unset extra tagged when inclusive_vlans is true" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["1", ["18"]])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface vlan 28").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["20", "28"], true, interface_info, :true)
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

    it "should add tagged vlans and unset any that are untagged when inclusive_vlans is true" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["20", []])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      msg = "Untagged VLAN configuration cannot be updated when inclusive vlan flag is true"
      expect {base.update_vlans(transport, ["20", "28"], true, interface_info, :true)}.to raise_error(msg)
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

    it "should not set untagged vlan when inclusive vlans flag is true" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["1", []])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect {base.update_vlans(transport, ["18"], false, interface_info, :true)}.to raise_error
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

    it "should not remove existing tagged vlan when inclusive flag is true" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["20", ["29"]])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 28").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["28"], true, interface_info, :true)
    end

    it "should not remove existing untagged when inclusive flag is true" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["20", ["29"]])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect{ base.update_vlans(transport, ["21"], false, interface_info, :true)}.to raise_error
    end

    it "should remove extra vlan when inclusive vlan flag is false" do
      expect(base).to receive(:show_interface_vlans)
                          .with(transport, interface_type, interface_id)
                          .and_return(["20", ["29"]])
      expect(transport).to receive(:command).twice.with("exit").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("no untagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 29").ordered
      expect(transport).to receive(:command).with("no tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("exit").ordered
      expect(transport).to receive(:command).with("interface vlan 20").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface vlan 28").ordered
      expect(transport).to receive(:command).with("tagged Tengigabit 0/4").ordered
      expect(transport).to receive(:command).with("interface Tengigabit 0/4").ordered
      base.update_vlans(transport, ["20", "28"], true, interface_info)
    end
  end

  describe "#show_stp_val" do
    let(:interface_type) { "Te 0/14" }
    it "should parse only existing spanning-tree protcol edge-port"do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/show_switch_spt.out")
      transport.stub(:command).with("show config").and_return(out)
      expect(base.show_stp_val(transport,"Te 0/14")).to eq(["mstp","rstp","pvst"])
    end
    it "should parse no spanning-tree edge-port"do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/show_switch_no_spt.out")
      transport.stub(:command).with("show config").and_return(out)
      expect(base.show_stp_val(transport,"Te 0/14")).to eq([])
    end
  end

  describe"get_existing_port_channel" do
    let(:interface_type) { "Tengigabit" }
    let(:interface_id) { "0/14" }
    it "should return a port channel that is configured with current interface" do
      expect(base).to receive(:name).and_return("Te 0/14")
      expect(transport).to receive(:command).twice.with("exit")
      transport.stub(:command).with("show interface port-channel br").and_return("  3  L3  up  00:00:00:00 tf 1/41 (down)")
      expect(transport).to receive(:command).with("conf")
      expect(transport).to receive(:command).with("interface Te 0/14")

      base.get_existing_port_channel(transport, base.name)
    end
  end

  describe "#update_stp"do
    it "should add valid spanning-tree protocol type"do
     expect(transport).to receive(:command).with("config").ordered
     expect(transport).to receive(:command).with("interface Te 0/14").ordered
     expect(transport).to receive(:command).with("spanning-tree mvst edge-port").ordered
     expect(transport).to receive(:command).with("config").ordered
     expect(transport).to receive(:command).with("interface Te 0/14").ordered
     expect(transport).to receive(:command).with("spanning-tree rstp edge-port").ordered
     base.update_stp(transport,"Te 0/14",["pvst"],["mvst","rstp","pvst"])
    end

    it "should add correct spanning-tree protocol type"do
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("no spanning-tree mvst edge-port").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("no spanning-tree rstp edge-port").ordered
      expect(transport).to receive(:command).with("config").ordered
      expect(transport).to receive(:command).with("interface Te 0/14").ordered
      expect(transport).to receive(:command).with("spanning-tree pvst edge-port").ordered
      base.update_stp(transport,"Te 0/14", ["mvst","rstp"],["pvst"])
    end

     it "should add parsed spanning-tree protocol type"do
       expect(transport).to receive(:command).with("config").ordered
       expect(transport).to receive(:command).with("interface Te 0/14").ordered
       expect(transport).to receive(:command).with("spanning-tree pvst edge-port").ordered
       base.update_stp(transport,"Te 0/14", [],["pvst"])
     end
  end
end




