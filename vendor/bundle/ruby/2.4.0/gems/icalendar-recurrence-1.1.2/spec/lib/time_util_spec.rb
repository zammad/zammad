require 'spec_helper'

describe TimeUtil do
  describe ".datetime_to_time" do
    it "converts DateTime to Time correctly" do
      datetime = Icalendar::Values::DateTime.new(DateTime.parse("2014-01-27T12:55:21-08:00"))
      correct_time = Time.parse("2014-01-27T12:55:21-08:00")
      expect(TimeUtil.datetime_to_time(datetime)).to eq(correct_time)
    end

    it "converts UTC datetime to time with no offset" do
      utc_datetime = Icalendar::Values::DateTime.new(DateTime.parse("20140114T180000Z"))
      expect(TimeUtil.datetime_to_time(utc_datetime).utc_offset).to eq(0)
    end

    it "converts PST datetime to time with 8 hour offset" do
      pst_datetime = Icalendar::Values::DateTime.new(DateTime.parse("2014-01-27T12:55:21-08:00"))
      expect(TimeUtil.datetime_to_time(pst_datetime).utc_offset).to eq(-8*60*60)
    end
  end

  describe ".to_time" do
    it "uses specified timezone ID offset while converting to a Time object" do
      utc_midnight = DateTime.parse("2014-01-27T12:00:00+00:00")
      pst_midnight =     Time.parse("2014-01-27T12:00:00-08:00")

      zoned_datetime = Icalendar::Values::DateTime.new(utc_midnight, "tzid" => "America/Los_Angeles")

      expect(TimeUtil.to_time(zoned_datetime)).to eq(pst_midnight)
    end

    it "parses a string" do
      expect(TimeUtil.to_time("20140118T075959Z")).to eq(Time.parse("20140118T075959Z"))
    end
  end

  describe ".date_to_time" do
    it "converts date to time object in local time" do
      local_time = Time.parse("2014-01-01")
      expect(TimeUtil.date_to_time(Date.parse("2014-01-01"))).to eq(local_time)
    end
  end

  describe "timezone_offset" do
    # Avoid DST changes by freezing time
    before { Timecop.freeze("2014-01-01") }
    after  { Timecop.return }

    it "calculates negative offset" do
      expect(TimeUtil.timezone_offset("America/Los_Angeles")).to eq("-08:00")
    end

    it "calculates positive offset" do
      expect(TimeUtil.timezone_offset("Europe/Amsterdam")).to eq("+01:00")
    end

    it "handles UTC zone" do
      expect(TimeUtil.timezone_offset("GMT")).to eq("+00:00")
    end

    it "returns nil when given an unknown timezone" do
      expect(TimeUtil.timezone_offset("Foo/Bar")).to eq(nil)
    end

    it "removes quotes from given TZID" do
      expect(TimeUtil.timezone_offset("\"America/Los_Angeles\"")).to eq("-08:00")
    end

    it "uses first element from array when given" do
      expect(TimeUtil.timezone_offset(["America/Los_Angeles"])).to eq("-08:00")
    end

    it "returns nil when given nil" do
      expect(TimeUtil.timezone_offset(nil)).to eq(nil)
    end

    it "calculates offset at a given moment" do
      after_daylight_savings = Date.parse("2014-05-01")
      expect(TimeUtil.timezone_offset("America/Los_Angeles", moment: after_daylight_savings)).to eq("-07:00")
    end

    it "handles daylight savings" do
      # FYI, clocks turn forward an hour on Nov 2 at 9:00:00 UTC
      minute_before_clocks_change = Time.parse("2014-11-02 at 08:59:00 UTC") # on west coast
      minute_after_clocks_change  = Time.parse("2014-11-02 at 09:01:00 UTC") # on west coast

      expect(TimeUtil.timezone_offset("America/Los_Angeles", moment: minute_before_clocks_change)).to eq("-07:00")
      expect(TimeUtil.timezone_offset("America/Los_Angeles", moment: minute_after_clocks_change)).to eq("-08:00")
    end
  end

  describe ".force_zone" do
    it "replaces the exist offset with the offset from a named zone" do
      eight_am_utc = Time.parse("20140101T0800Z")
      forced_time = TimeUtil.force_zone(eight_am_utc, "America/Los_Angeles")
      expect(forced_time.utc.to_s).to eq("2014-01-01 16:00:00 UTC")
    end

    context "when forced timezone is different than original" do
      it "changes the moment in time the object refers to" do
        eight_am_utc = Time.parse("20140101T0800Z")
        forced_time = TimeUtil.force_zone(eight_am_utc, "America/Los_Angeles")
        expect(forced_time.to_i).to_not eq(eight_am_utc.to_i)
      end
    end

    it "works for non-UTC time" do
      eight_am_local = Time.parse("2014-01-01 08:00")
      forced_time = TimeUtil.force_zone(eight_am_local, "Asia/Hong_Kong")
      expect(forced_time.utc.to_s).to eq("2014-01-01 00:00:00 UTC")
    end

    context "when given an unknown TZID" do
      it "raises an error" do
        expect {
          TimeUtil.force_zone(Time.now, "Foo/Bar")
        }.to raise_error(ArgumentError)
      end
    end

    it "works with this example" do
      forced_time = Time.parse("2014-01-04 at 4pm").force_zone("America/Los_Angeles")
      expect(forced_time.hour).to eq(16)
    end

    it "extends Time" do
      forced_time = Time.parse("2014-01-01 at 8am").force_zone("Asia/Hong_Kong")
      expect(forced_time.utc.to_s).to eq("2014-01-01 00:00:00 UTC")
    end

    it "doesn't change passed in time objects to UTC" do
      eight_am_local = Time.parse("2014-01-01 08:00")
      TimeUtil.force_zone(eight_am_local, "Asia/Hong_Kong")
      expect(eight_am_local.utc?).to eq(false)
    end
  end
end
