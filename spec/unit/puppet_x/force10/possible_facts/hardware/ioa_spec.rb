require 'spec_helper'
require 'puppet_x/force10/possible_facts/hardware/ioa'

describe PuppetX::Force10::PossibleFacts::Hardware::Ioa do
  let(:ioa) {PuppetX::Force10::PossibleFacts::Hardware::Ioa}
  let(:fact_fixtures) {PuppetSpec::FIXTURE_DIR}
  let(:sh_running_config) {File.read(File.join(fact_fixtures, "show_running_config_interface"))}

  describe "#vlan_information" do
    it "should return the correct fact data" do
      vlan_info = ioa.vlan_information(sh_running_config)
      expect(vlan_info).to include("1")
      expect(vlan_info["1"]).to eq({"tagged_tengigabit"=>["0/3", "0/5", "0/7", "0/8", "0/10", "0/11", "0/13", "0/16", "0/17", "0/18", "0/19", "0/21", "0/22", "0/23", "0/24", "0/25", "0/26", "0/27", "0/29", "0/30", "0/31", "0/32"],
                                        "untagged_tengigabit"=>["0/6", "0/12", "0/14", "0/15", "0/28"],
                                        "tagged_fortygigabit"=>[],
                                        "untagged_fortygigabit"=>[],
                                        "tagged_portchannel"=>[],
                                        "untagged_portchannel"=>[]})
      expect(vlan_info).to include("48")
      expect(vlan_info["48"]).to eq({"tagged_tengigabit"=>["0/3", "0/5", "0/7", "0/8", "0/10", "0/11", "0/13", "0/16", "0/17", "0/18", "0/19", "0/21", "0/22", "0/23", "0/24", "0/25", "0/26", "0/27", "0/29", "0/30", "0/31", "0/32"],
                                     "untagged_tengigabit"=>["0/4", "0/9"],
                                     "tagged_fortygigabit"=>[],
                                     "untagged_fortygigabit"=>[],
                                     "tagged_portchannel"=>[],
                                     "untagged_portchannel"=>[]})
    end
  end
end