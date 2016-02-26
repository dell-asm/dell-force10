require "spec_helper"
require "puppet_x/force10/model/interface/base"

describe PuppetX::Force10::Model::Interface::Base do
  let (:base) { PuppetX::Force10::Model::Interface::Base }

  describe "#show_interface_vlans" do
    it "should parse only untagged vlan" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/only_untagged.out")
      transport = Object.new
      transport.stub(:command).with("show interfaces switchport Tengigabitethernet 0/4").and_return(out)
      expect(base.show_interface_vlans(transport, "Tengigabitethernet", "0/4")).to eq(["25", []])
    end

    it "should parse untagged and tagged vlan" do
      out = PuppetSpec.load_fixture("show_interfaces_switchport/tagged_and_untagged.out")
      transport = Object.new
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
end