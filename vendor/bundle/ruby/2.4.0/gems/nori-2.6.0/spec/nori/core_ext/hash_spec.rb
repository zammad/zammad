require "spec_helper"

describe Hash do

  describe "#normalize_param" do
    it "should have specs"
  end

  describe "#to_xml_attributes" do

    it "should turn the hash into xml attributes" do
      attrs = { :one => "ONE", "two" => "TWO" }.to_xml_attributes
      expect(attrs).to match(/one="ONE"/m)
      expect(attrs).to match(/two="TWO"/m)
    end

    it "should preserve _ in hash keys" do
      attrs = {
        :some_long_attribute => "with short value",
        :crash               => :burn,
        :merb                => "uses extlib"
      }.to_xml_attributes

      expect(attrs).to match(/some_long_attribute="with short value"/)
      expect(attrs).to match(/merb="uses extlib"/)
      expect(attrs).to match(/crash="burn"/)
    end
  end

end
